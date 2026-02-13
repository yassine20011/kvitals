#!/usr/bin/env bash
set -euo pipefail

PREV_CPU_FILE="/tmp/kde-sys-state-cpu-prev"
PREV_NET_FILE="/tmp/kde-sys-state-net-prev"
NET_IFACE="wlo1"

# --- CPU Usage (delta-based from /proc/stat) ---
read_cpu_raw() {
    awk '/^cpu / {print $2+$3+$4+$5+$6+$7+$8, $5}' /proc/stat
}

cpu_usage="0"
current_cpu=$(read_cpu_raw)
curr_total=$(echo "$current_cpu" | awk '{print $1}')
curr_idle=$(echo "$current_cpu" | awk '{print $2}')

if [[ -f "$PREV_CPU_FILE" ]]; then
    prev_total=$(awk '{print $1}' "$PREV_CPU_FILE")
    prev_idle=$(awk '{print $2}' "$PREV_CPU_FILE")
    diff_total=$((curr_total - prev_total))
    diff_idle=$((curr_idle - prev_idle))
    if [[ $diff_total -gt 0 ]]; then
        cpu_usage=$(awk "BEGIN {printf \"%.0f\", ($diff_total - $diff_idle) * 100.0 / $diff_total}")
    fi
fi
echo "$curr_total $curr_idle" > "$PREV_CPU_FILE"

# --- RAM ---
ram_info=$(free -b | awk '/^Mem:/ {printf "%.1f %.1f", $3/1073741824, $2/1073741824}')
ram_used=$(echo "$ram_info" | awk '{print $1}')
ram_total=$(echo "$ram_info" | awk '{print $2}')

# --- CPU Temperature ---
cpu_temp="N/A"
for zone in /sys/class/thermal/thermal_zone*/temp; do
    if [[ -f "$zone" ]]; then
        type_file="${zone%temp}type"
        if [[ -f "$type_file" ]] && grep -qi "x86_pkg_temp\|coretemp\|cpu" "$type_file" 2>/dev/null; then
            raw=$(cat "$zone")
            cpu_temp=$((raw / 1000))
            break
        fi
    fi
done
# Fallback: just use the first thermal zone
if [[ "$cpu_temp" == "N/A" ]]; then
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [[ -f "$zone" ]]; then
            raw=$(cat "$zone")
            cpu_temp=$((raw / 1000))
            break
        fi
    done
fi

# --- Battery ---
bat_capacity="N/A"
bat_status=""
if [[ -f /sys/class/power_supply/BAT0/capacity ]]; then
    bat_capacity=$(cat /sys/class/power_supply/BAT0/capacity)
    if [[ -f /sys/class/power_supply/BAT0/status ]]; then
        bat_status=$(cat /sys/class/power_supply/BAT0/status)
    fi
fi

# --- Network Speed (delta-based from /proc/net/dev) ---
net_down="0"
net_up="0"
now=$(date +%s)

read_net_raw() {
    awk -v iface="$NET_IFACE:" '$1 == iface {print $2, $10}' /proc/net/dev
}

current_net=$(read_net_raw)
curr_rx=$(echo "$current_net" | awk '{print $1}')
curr_tx=$(echo "$current_net" | awk '{print $2}')

if [[ -n "$curr_rx" ]] && [[ -f "$PREV_NET_FILE" ]]; then
    prev_rx=$(awk '{print $1}' "$PREV_NET_FILE")
    prev_tx=$(awk '{print $2}' "$PREV_NET_FILE")
    prev_time=$(awk '{print $3}' "$PREV_NET_FILE")
    diff_time=$((now - prev_time))
    if [[ $diff_time -gt 0 ]]; then
        net_down=$(awk "BEGIN {printf \"%.1f\", ($curr_rx - $prev_rx) / $diff_time / 1024}")
        net_up=$(awk "BEGIN {printf \"%.1f\", ($curr_tx - $prev_tx) / $diff_time / 1024}")
    fi
fi
if [[ -n "$curr_rx" ]]; then
    echo "$curr_rx $curr_tx $now" > "$PREV_NET_FILE"
fi

# Format net speed with appropriate unit
format_speed() {
    local kb="$1"
    local val
    val=$(echo "$kb" | awk '{v=$1; if(v<0) v=0; print v}')
    if (( $(echo "$val >= 1024" | bc -l) )); then
        echo "$(awk "BEGIN {printf \"%.1f\", $val/1024}")M"
    else
        echo "${val}K"
    fi
}

net_down_fmt=$(format_speed "$net_down")
net_up_fmt=$(format_speed "$net_up")

# --- Battery icon ---
bat_icon=""
if [[ "$bat_status" == "Charging" ]]; then
    bat_icon="⚡"
elif [[ "$bat_status" == "Discharging" ]]; then
    bat_icon="🔋"
fi

# --- Output JSON ---
cat <<EOF
{"cpu":${cpu_usage},"ram_used":"${ram_used}","ram_total":"${ram_total}","temp":"${cpu_temp}","bat":"${bat_capacity}","bat_status":"${bat_status}","bat_icon":"${bat_icon}","net_down":"${net_down_fmt}","net_up":"${net_up_fmt}"}
EOF
