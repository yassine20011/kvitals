#!/usr/bin/env bash
set -euo pipefail

# Configuration

readonly PREV_CPU_FILE="/tmp/kde-sys-state-cpu-prev"
readonly PREV_NET_FILE="/tmp/kde-sys-state-net-prev"

detect_net_iface() {
    # 1. Use script argument if provided and not "auto"
    if [[ -n "${1:-}" && "$1" != "auto" ]]; then
        echo "$1"
        return
    fi

    # 2. Auto-detect from default route
    local iface
    iface=$(ip route 2>/dev/null | awk '/^default/ {print $5; exit}')
    if [[ -n "$iface" ]]; then
        echo "$iface"
        return
    fi

    # 3. Fallback: first non-lo interface
    for iface in /sys/class/net/*/; do
        iface=$(basename "$iface")
        if [[ "$iface" != "lo" ]]; then
            echo "$iface"
            return
        fi
    done

    echo "lo"
}

NET_IFACE=$(detect_net_iface "${1:-}")
readonly NET_IFACE

# CPU Usage (delta-based from /proc/stat)

get_cpu() {
    local current_cpu curr_total curr_idle cpu_usage=0

    current_cpu=$(awk '/^cpu / {print $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat)
    curr_total=${current_cpu%% *}
    curr_idle=${current_cpu##* }

    if [[ -f "$PREV_CPU_FILE" ]]; then
        local prev_total prev_idle diff_total diff_idle
        read -r prev_total prev_idle < "$PREV_CPU_FILE"
        diff_total=$((curr_total - prev_total))
        diff_idle=$((curr_idle - prev_idle))
        if [[ $diff_total -gt 0 ]]; then
            cpu_usage=$(( (diff_total - diff_idle) * 100 / diff_total ))
        fi
    fi

    echo "$curr_total $curr_idle" > "$PREV_CPU_FILE"
    echo "$cpu_usage"
}

# RAM Usage

get_ram() {
    awk '/^Mem:/ {printf "%.1f %.1f", $3/1073741824, $2/1073741824}' <(free -b)
}

# CPU Temperature (4-tier fallback, Intel + AMD)

get_temp() {
    local zone type_file raw name hwmon

    # Try 1: thermal_zone sysfs (CPU-matched — Intel & AMD labels)
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        [[ -f "$zone" ]] || continue
        type_file="${zone%temp}type"
        if [[ -f "$type_file" ]] && grep -qi "x86_pkg_temp\|coretemp\|k10temp\|zenpower\|cpu" "$type_file" 2>/dev/null; then
            raw=$(<"$zone")
            echo $((raw / 1000))
            return
        fi
    done

    # Try 2: hwmon (coretemp / k10temp / zenpower / zenergy / amdgpu)
    for hwmon in /sys/class/hwmon/hwmon*/; do
        [[ -f "${hwmon}name" ]] || continue
        name=$(<"${hwmon}name")
        case "$name" in
            coretemp|k10temp|zenpower|zenergy|amdgpu)
                if [[ -f "${hwmon}temp1_input" ]]; then
                    raw=$(<"${hwmon}temp1_input")
                    echo $((raw / 1000))
                    return
                fi
                ;;
        esac
    done

    # Try 3: lm-sensors command (Intel: Package id / AMD: Tctl, Tdie, Tccd)
    if command -v sensors &>/dev/null; then
        local temp
        temp=$(sensors 2>/dev/null | awk '/^(Package id 0|Tctl|Tdie|Tccd1|Core 0):/ {gsub(/[^0-9.]/, "", $NF); printf "%.0f", $NF; exit}')
        if [[ -n "$temp" ]]; then
            echo "$temp"
            return
        fi
    fi

    # Try 4: first available thermal zone (generic fallback)
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [[ -f "$zone" ]]; then
            raw=$(<"$zone")
            echo $((raw / 1000))
            return
        fi
    done

    echo "N/A"
}

# Battery Status

get_battery() {
    local capacity="N/A" status="" icon=""

    if [[ -f /sys/class/power_supply/BAT0/capacity ]]; then
        capacity=$(</sys/class/power_supply/BAT0/capacity)
        [[ -f /sys/class/power_supply/BAT0/status ]] && status=$(<"/sys/class/power_supply/BAT0/status")
    fi

    case "$status" in
        Charging)    icon="⚡" ;;
        Discharging) icon="🔋" ;;
    esac

    echo "$capacity $status $icon"
}

# Power Consumption (from /sys/class/power_supply/)

get_power() {
    local power_supply_dir="/sys/class/power_supply"
    local total_power=0
    local power_count=0
    local sign=""
    
    # Check if power_supply directory exists
    if [[ ! -d "$power_supply_dir" ]]; then
        echo "N/A N/A"
        return
    fi
    
    # Iterate through all power supply devices
    for bat_dir in "$power_supply_dir"/*; do
        [[ -d "$bat_dir" ]] || continue
        
        local type_file="$bat_dir/type"
        
        # Check if it's a battery device
        if [[ -f "$type_file" ]]; then
            local device_type
            device_type=$(<"$type_file")
            if [[ "$device_type" != "Battery" ]]; then
                continue
            fi
        else
            continue
        fi
        
        local power=0
        local power_now="$bat_dir/power_now"
        local current_now="$bat_dir/current_now"
        local voltage_now="$bat_dir/voltage_now"
        local status_file="$bat_dir/status"
        
        # Try to read power_now directly
        if [[ -f "$power_now" ]]; then
            local power_val
            power_val=$(<"$power_now")
            # Check if value is valid (not empty and is a number)
            if [[ -n "$power_val" && "$power_val" =~ ^-?[0-9]+$ ]]; then
                # Convert from microwatts to watts, take absolute value
                power=$(awk "BEGIN {printf \"%.1f\", ($power_val < 0 ? -$power_val : $power_val) / 1000000}")
            else
                continue
            fi
        # Otherwise calculate from current and voltage
        elif [[ -f "$current_now" && -f "$voltage_now" ]]; then
            local current_val voltage_val
            current_val=$(<"$current_now")
            voltage_val=$(<"$voltage_now")
            # Check if both values are valid (not empty and are numbers)
            if [[ -n "$current_val" && "$current_val" =~ ^-?[0-9]+$ ]] && \
               [[ -n "$voltage_val" && "$voltage_val" =~ ^-?[0-9]+$ ]]; then
                # Calculate power in watts, take absolute value
                power=$(awk "BEGIN {val = ($current_val * $voltage_val) / 1000000000000; printf \"%.1f\", (val < 0 ? -val : val)}")
            else
                continue
            fi
        else
            continue
        fi
        
        # Get charging/discharging status
        if [[ -f "$status_file" ]]; then
            local status
            status=$(<"$status_file")
            case "$status" in
                Charging)    sign="+" ;;
                Discharging) sign="-" ;;
                *)           sign="" ;;
            esac
        fi
        
        total_power=$(awk "BEGIN {printf \"%.1f\", $total_power + $power}")
        ((power_count++))
    done
    
    if [[ $power_count -eq 0 ]]; then
        echo "N/A N/A"
    else
        echo "$total_power $sign"
    fi
}

# Network Speed (delta-based from /proc/net/dev)

format_speed() {
    local val="$1"
    if awk "BEGIN {exit !($val >= 1024)}" 2>/dev/null; then
        awk "BEGIN {printf \"%.1fM\", $val/1024}"
    else
        awk "BEGIN {v=$val; if(v<0) v=0; printf \"%.1fK\", v}"
    fi
}

get_network() {
    local curr_rx curr_tx now net_down=0 net_up=0
    now=$(date +%s)

    read -r curr_rx curr_tx < <(
        awk -v iface="$NET_IFACE:" '$1 == iface {print $2, $10}' /proc/net/dev
    ) || true

    if [[ -n "${curr_rx:-}" ]] && [[ -f "$PREV_NET_FILE" ]]; then
        local prev_rx prev_tx prev_time diff_time
        read -r prev_rx prev_tx prev_time < "$PREV_NET_FILE"
        diff_time=$((now - prev_time))
        if [[ $diff_time -gt 0 ]]; then
            net_down=$(awk "BEGIN {printf \"%.1f\", ($curr_rx - $prev_rx) / $diff_time / 1024}")
            net_up=$(awk "BEGIN {printf \"%.1f\", ($curr_tx - $prev_tx) / $diff_time / 1024}")
        fi
    fi

    [[ -n "${curr_rx:-}" ]] && echo "$curr_rx $curr_tx $now" > "$PREV_NET_FILE"

    echo "$(format_speed "$net_down") $(format_speed "$net_up")"
}

# JSON Output

output_json() {
    local cpu="$1" ram_used="$2" ram_total="$3" temp="$4"
    local bat_capacity="$5" bat_status="$6" bat_icon="$7"
    local net_down="$8" net_up="$9"
    local power="${10}" power_sign="${11}"

    cat <<EOF
{"cpu":${cpu},"ram_used":"${ram_used}","ram_total":"${ram_total}","temp":"${temp}","bat":"${bat_capacity}","bat_status":"${bat_status}","bat_icon":"${bat_icon}","net_down":"${net_down}","net_up":"${net_up}","power":"${power}","power_sign":"${power_sign}"}
EOF
}

# Main

main() {
    local cpu ram_used ram_total temp
    local bat_capacity bat_status bat_icon
    local net_down net_up
    local power power_sign

    cpu=$(get_cpu)

    local ram_info
    ram_info=$(get_ram)
    ram_used=${ram_info%% *}
    ram_total=${ram_info##* }

    temp=$(get_temp)

    local bat_info
    bat_info=$(get_battery)
    bat_capacity=$(echo "$bat_info" | awk '{print $1}')
    bat_status=$(echo "$bat_info" | awk '{print $2}')
    bat_icon=$(echo "$bat_info" | awk '{print $3}')

    local net_info
    net_info=$(get_network)
    net_down=${net_info%% *}
    net_up=${net_info##* }

    local power_info
    power_info=$(get_power)
    power=$(echo "$power_info" | awk '{print $1}')
    power_sign=$(echo "$power_info" | awk '{print $2}')

    output_json "$cpu" "$ram_used" "$ram_total" "$temp" \
                "$bat_capacity" "$bat_status" "$bat_icon" \
                "$net_down" "$net_up" \
                "$power" "$power_sign"
}

main
