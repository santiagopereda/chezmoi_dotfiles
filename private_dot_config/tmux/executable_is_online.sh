#!/bin/sh
# Show internet latency or offline icon
case "$(uname -s)" in
  Darwin) timeout="-W 1000" ;;  # macOS: milliseconds
  *)      timeout="-W 1" ;;     # Linux: seconds
esac
ping -c 1 $timeout google.com 2>/dev/null \
  | awk -F'time=' '/time=/{printf "󰨀 %.0f ms", $2; found=1} END{if(!found) printf "󱍢"}'
