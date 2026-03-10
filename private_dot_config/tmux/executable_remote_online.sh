#!/bin/zsh

IP="$(ps -af | grep 'ssh' | cut -d '@' -f2 | head -n 1)" # Replace with the IP address you want to ping
COUNT=1 # Number of ping attempts

speed=$(tail -1 /tmp/lighthouse.txt)

if [ $speed ]; then
    ping_output="󰢹 $speed ms"
    rm /tmp/lighthouse.txt
else
    touch /tmp/lighthouse.txt
    ping_output=""
fi
echo "$ping_output"


ping $IP -c 10 | tail -1 | cut -d "/" -f5 >> /tmp/lighthouse.txt