#!/usr/bin/env bash
# Install (or remove with --uninstall) the CPU/memory alert as a systemd user service.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
UNIT_DIR="$HOME/.config/systemd/user"

if [[ "${1:-}" == "--uninstall" ]]; then
    systemctl --user disable --now cpu-alert.service 2>/dev/null || true
    rm -f "$BIN/cpu-alert" "$BIN/cpu-alert-popup" "$UNIT_DIR/cpu-alert.service"
    systemctl --user daemon-reload
    echo "cpu-alert uninstalled."
    exit 0
fi

if ! python3 -c "import gi; gi.require_version('Gtk', '3.0')" 2>/dev/null; then
    echo "Missing GTK3 Python bindings. Install them with:" >&2
    echo "  sudo apt install python3-gi gir1.2-gtk-3.0" >&2
    exit 1
fi

install -Dm755 "$SRC/bin/cpu-alert" "$BIN/cpu-alert"
install -Dm755 "$SRC/bin/cpu-alert-popup" "$BIN/cpu-alert-popup"
install -Dm644 "$SRC/systemd/cpu-alert.service" "$UNIT_DIR/cpu-alert.service"

systemctl --user daemon-reload
systemctl --user enable cpu-alert.service
systemctl --user restart cpu-alert.service

echo "cpu-alert installed and running. Logs: journalctl --user -u cpu-alert -f"
