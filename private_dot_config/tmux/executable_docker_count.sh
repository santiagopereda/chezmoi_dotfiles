#!/bin/sh
# Show running Docker container count — silent when Docker is unavailable or idle
command -v docker >/dev/null 2>&1 || exit 0
count=$(docker ps -q 2>/dev/null | wc -l)
[ "$count" -gt 0 ] && printf "󰡨 %s" "$count"
