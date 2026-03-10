#!/bin/zsh

IP="google.com" # Replace with the IP address you want to ping
COUNT=1 # Number of ping attempts

speed=$(tail -1 /tmp/ping.txt)

if [ $speed ]; then
    ping_output="󰨀 $speed ms"
    rm /tmp/ping.txt
else
    touch /tmp/ping.txt
    ping_output="󱍢"
fi
echo "$ping_output"


ping www.google.com -c 1 | tail -1 | cut -d "/" -f5 >> /tmp/ping.txt