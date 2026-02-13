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

# CPU Temperature (4-tier fallback)

get_temp() {
    local zone type_file raw name hwmon

    # Try 1: thermal_zone sysfs (CPU-matched)
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        [[ -f "$zone" ]] || continue
        type_file="${zone%temp}type"
        if [[ -f "$type_file" ]] && grep -qi "x86_pkg_temp\|coretemp\|cpu" "$type_file" 2>/dev/null; then
            raw=$(<"$zone")
            echo $((raw / 1000))
            return
        fi
    done

    # Try 2: first available thermal zone
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [[ -f "$zone" ]]; then
            raw=$(<"$zone")
            echo $((raw / 1000))
            return
        fi
    done

    # Try 3: hwmon (coretemp / k10temp / zenpower)
    for hwmon in /sys/class/hwmon/hwmon*/; do
        [[ -f "${hwmon}name" ]] || continue
        name=$(<"${hwmon}name")
        if [[ "$name" == "coretemp" || "$name" == "k10temp" || "$name" == "zenpower" ]]; then
            if [[ -f "${hwmon}temp1_input" ]]; then
                raw=$(<"${hwmon}temp1_input")
                echo $((raw / 1000))
                return
            fi
        fi
    done

    # Try 4: lm-sensors command
    if command -v sensors &>/dev/null; then
        local temp
        temp=$(sensors 2>/dev/null | awk '/^(Package id 0|Tctl|Tdie|Core 0):/ {gsub(/[^0-9.]/, "", $NF); printf "%.0f", $NF; exit}')
        if [[ -n "$temp" ]]; then
            echo "$temp"
            return
        fi
    fi

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

    cat <<EOF
{"cpu":${cpu},"ram_used":"${ram_used}","ram_total":"${ram_total}","temp":"${temp}","bat":"${bat_capacity}","bat_status":"${bat_status}","bat_icon":"${bat_icon}","net_down":"${net_down}","net_up":"${net_up}"}
EOF
}

# Main

main() {
    local cpu ram_used ram_total temp
    local bat_capacity bat_status bat_icon
    local net_down net_up

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

    output_json "$cpu" "$ram_used" "$ram_total" "$temp" \
                "$bat_capacity" "$bat_status" "$bat_icon" \
                "$net_down" "$net_up"
}

main
