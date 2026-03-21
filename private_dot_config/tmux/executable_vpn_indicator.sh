#!/bin/sh
# Show VPN status — detects tun, wg, and tailscale interfaces
for iface in tun0 tun1 wg0 wg1 tailscale0; do
  if [ -d "/sys/class/net/$iface" ]; then
    printf "󰌾 VPN"
    exit 0
  fi
done

# macOS: check Tailscale status via CLI (inside app bundle)
if [ "$(uname -s)" = "Darwin" ]; then
  ts="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
  if [ -x "$ts" ] && "$ts" status >/dev/null 2>&1; then
    printf "󰌾 VPN"
    exit 0
  fi
fi
