#!/usr/bin/env bash
set -euo pipefail

echo "=== Removing Snap from Kubuntu ==="

# Check for root/sudo access
sudo -v

echo "[1/5] Removing installed Snap packages..."
if command -v snap >/dev/null 2>&1; then
    while read -r snap_name; do
        [[ -z "$snap_name" ]] && continue
        echo "  Removing: $snap_name"
        sudo snap remove --purge "$snap_name" || true
    done < <(snap list 2>/dev/null | awk 'NR > 1 {print $1}')
fi

echo "[2/5] Stopping and disabling Snap services..."
sudo systemctl stop snapd.service snapd.socket 2>/dev/null || true
sudo systemctl disable snapd.service snapd.socket 2>/dev/null || true

echo "[3/5] Purging Snap packages..."
sudo apt purge -y snapd plasma-discover-backend-snap
sudo apt autoremove --purge -y

echo "[4/5] Removing leftover Snap data..."
sudo rm -rf \
    /var/cache/snapd \
    /var/lib/snapd \
    /var/snap \
    /snap

rm -rf "$HOME/snap"

echo "[5/5] Preventing Snap from being installed again..."
sudo tee /etc/apt/preferences.d/no-snap.pref >/dev/null <<'EOF'
Package: snapd
Pin: release *
Pin-Priority: -1
EOF

sudo apt update

echo
echo "=== Snap removal complete ==="
echo
echo "Verification:"
echo -n "snap command: "
if command -v snap >/dev/null 2>&1; then
    echo "STILL INSTALLED"
else
    echo "removed"
fi

echo -n "snapd package: "
if dpkg-query -W -f='${Status}' snapd 2>/dev/null | grep -q "install ok installed"; then
    echo "STILL INSTALLED"
else
    echo "removed"
fi

echo
echo "APT pin:"
cat /etc/apt/preferences.d/no-snap.pref
