#!/usr/bin/env bash
# Setup RAPL permissions for KVitals
# This allows the RAPL file to be readable without sudo

set -e

RAPL_FILE="/sys/class/powercap/intel-rapl:0/energy_uj"
SYSTEMD_SERVICE_DIR="/etc/systemd/system"
SYSTEMD_SERVICE_FILE="$SYSTEMD_SERVICE_DIR/rapl-chmod.service"

echo "Setting up RAPL permissions for KVitals..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Use: sudo bash setup-rapl-udev.sh"
   exit 1
fi

# Check if RAPL file exists
if [[ ! -f "$RAPL_FILE" ]]; then
   echo "❌ Error: RAPL file not found at $RAPL_FILE"
   echo "Your CPU may not support RAPL or the file path is different."
   exit 1
fi

# Make the file readable right now
echo "Making RAPL file readable..."
chmod 644 "$RAPL_FILE"

# Create systemd service to restore permissions at boot
echo "Creating systemd service for auto-restoring RAPL permissions..."
cat > "$SYSTEMD_SERVICE_FILE" <<'EOF'
[Unit]
Description=Make RAPL file readable for KVitals
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'until [ -e /sys/class/powercap/intel-rapl:0/energy_uj ]; do sleep 1; done; chmod 644 /sys/class/powercap/intel-rapl:0/energy_uj'
TimeoutStartSec=15

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
echo "Enabling systemd service..."
systemctl daemon-reload
systemctl enable rapl-chmod.service

echo "✅ RAPL permissions configured successfully!"
echo ""
echo "The RAPL file is now readable and will be auto-restored at every boot."
echo ""
echo "Next steps:"
echo "  1. Restart Plasma: kquitapp6 plasmashell && kstart plasmashell &"
echo "  2. Toggle 'Show power draw' in widget settings"
echo ""
echo "To check if it's working:"
echo "  cat $RAPL_FILE"
