#!/usr/bin/env bash

# Status display

# Most of this taken from the PADD project by Jim McKenna - https://github.com/jpmck/PADD/

declare -i core_count=1
core_count=$(cat /sys/devices/system/cpu/kernel_max 2> /dev/null)+1

# COLORS
black_text=$(tput setaf 0)   # Black
red_text=$(tput setaf 1)     # Red
green_text=$(tput setaf 2)   # Green
yellow_text=$(tput setaf 3)  # Yellow
blue_text=$(tput setaf 4)    # Blue
magenta_text=$(tput setaf 5) # Magenta
cyan_text=$(tput setaf 6)    # Cyan
white_text=$(tput setaf 7)   # White
reset_text=$(tput sgr0)      # Reset to default color

# STYLES
bold_text=$(tput bold)
blinking_text=$(tput blink)
dim_text=$(tput dim)

HeatmapGenerator () {
    # if one number is provided, just use that percentage to figure out the colors
    if [ -z "$2" ]; then
        load=$(printf "%.0f" "$1")
    # if two numbers are provided, do some math to make a percentage to figure out the colors
    else
        load=$(printf "%.0f" "$(echo "$1 $2" | awk '{print ($1 / $2) * 100}')")
    fi

    # Color logic
    #  |<-                 green                  ->| yellow |  red ->
    #  0  5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100
    if [ "${load}" -lt 75 ]; then
        out=${green_text}
    elif [ "${load}" -lt 90 ]; then
        out=${yellow_text}
    else
        out=${red_text}
    fi

    echo "$out"
}

GetSystemInformation() {
    # System uptime
    system_uptime=$(uptime | awk -F'( |,|:)+' '{if ($7=="min") m=$6; else {if ($7~/^day/){if ($9=="min") {d=$6;m=$8} else {d=$6;h=$8;m=$9}} else {h=$6;m=$7}}} {print d+0,"days,",h+0,"hours,",m+0,"minutes"}')

    # CPU temperature
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        cpu=$(</sys/class/thermal/thermal_zone0/temp)
    else
        cpu=0
    fi

    temperature="$(printf %.1f "$(echo "${cpu}" | awk '{print $1 / 1000}')")°C"

    # CPU load, heatmap
    read -r -a cpu_load < /proc/loadavg
    cpu_load_1_heatmap=$(HeatmapGenerator "${cpu_load[0]}" "${core_count}")
    cpu_load_5_heatmap=$(HeatmapGenerator "${cpu_load[1]}" "${core_count}")
    cpu_load_15_heatmap=$(HeatmapGenerator "${cpu_load[2]}" "${core_count}")
    cpu_percent=$(printf %.1f "$(echo "${cpu_load[0]} ${core_count}" | awk '{print ($1 / $2) * 100}')")

    # CPU temperature heatmap
    # If we're getting close to 85°C... (https://www.raspberrypi.org/blog/introducing-turbo-mode-up-to-50-more-performance-for-free/)
    if [ ${cpu} -gt 80000 ]; then
        temp_heatmap=${blinking_text}${red_text}
    elif [ ${cpu} -gt 70000 ]; then
        temp_heatmap=${magenta_text}
    elif [ ${cpu} -gt 60000 ]; then
        temp_heatmap=${blue_text}
    else
        temp_heatmap=${cyan_text}
    fi

    # Number of processes
    processes=$(ps ax | wc -l | tr -d " ")

    # Disk space
    if df -Pk | grep -E '^/dev/root' > /dev/null; then
        disk_space="`df -PkH | grep -E '^/dev/root' | awk '{ print $4 }'` (`df -Pk | grep -E '^/dev/root' | awk '{ print $5 }'` used) on /dev/root"
    else
        disk_space="`df -PkH | grep -E '^/dev/mmcblk0p2' | awk '{ print $4 }'` (`df -Pk | grep -E '^/dev/mmcblk0p2' | awk '{ print $5 }'` used) on /dev/mmcblk0p2"
    fi

    # Memory use, heatmap and bar
    memory_percent=$(awk '/MemTotal:/{total=$2} /MemFree:/{free=$2} /Buffers:/{buffers=$2} /^Cached:/{cached=$2} END {printf "%.1f", (total-free-buffers-cached)*100/total}' '/proc/meminfo')
    memory_heatmap=$(HeatmapGenerator "${memory_percent}")

    # Get pi IP address, hostname and gateway
    pi_ip_address=$(ip addr | grep 'eth0:.*state UP' -A2 | grep 'inet ' | tail -n1 | awk '{print $2}' | cut -f1  -d'/')
    pi_ip6_address=$(ip addr | grep 'eth0:.*state UP' -A4 | grep 'inet6 '| tail -n1 | awk '{print $2}' | cut -f1  -d'/')
    pi_hostname=$(hostname)
    pi_gateway=$(ip r | grep 'default' | awk '{print $3}')
}

PrintSystemInformation() {
    echo "${bold_text}SYSTEM =========================================================================${reset_text}"

    #Uptime and memory
    printf " %-10s%-39s %-10s %-6s\\n" "Uptime:" "${system_uptime}" "Memory:" "${memory_percent}%"

    # CPU temp, load, percentage
    printf " %-10s${temp_heatmap}%-10s${reset_text} %-10s${cpu_load_1_heatmap}%-4s${reset_text}, ${cpu_load_5_heatmap}%-4s${reset_text}, ${cpu_load_15_heatmap}%-7s${reset_text} %-10s %-6s\\n" "CPU Temp:" "${temperature}" "CPU Load:" "${cpu_load[0]}" "${cpu_load[1]}" "${cpu_load[2]}" "CPU Load:" "${cpu_percent}%"

    # Running processes and Disk space
    printf " %-10s %-8s %-12s%-20s\\n" "Processes:" "${processes}" "Disk Space:" "${disk_space}"

    # Network
    echo "${bold_text}NETWORK ========================================================================${reset_text}"
    printf " %-10s%-19s\\n" "Hostname:" "${pi_hostname}"
    printf " %-10s%-19s %-10s%-29s\\n" "IPv4 Adr:" "${pi_ip_address}" "IPv6 Adr:" "${pi_ip6_address}"
    printf " %-10s%-19s\\n" "Gateway:" "${pi_gateway}"
}

GetSystemInformation
PrintSystemInformation
