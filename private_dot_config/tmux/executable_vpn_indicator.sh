#!/bin/sh
# Show VPN status — detects tun, wg, and tailscale interfaces
for iface in tun0 tun1 wg0 wg1 tailscale0; do
  if [ -d "/sys/class/net/$iface" ]; then
    printf "󰌾 VPN"
    exit 0
  fi
done
