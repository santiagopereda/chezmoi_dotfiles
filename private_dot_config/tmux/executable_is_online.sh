#!/bin/sh
# Show internet latency or offline icon
ping -c 1 -W 1 google.com 2>/dev/null \
  | awk -F'time=' '/time=/{printf "󰨀 %.0f ms", $2; found=1} END{if(!found) printf "󱍢"}'
