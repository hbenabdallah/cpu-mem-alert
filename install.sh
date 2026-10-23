#!/usr/bin/env bash
# Install (or remove with --uninstall) the CPU/memory alert as a systemd user service.
# Works from a clone (./install.sh) or piped:
#   curl -fsSL https://raw.githubusercontent.com/hbenabdallah/cpu-mem-alert/main/install.sh | bash
set -euo pipefail

RAW_URL="https://raw.githubusercontent.com/hbenabdallah/cpu-mem-alert/main"
BIN="$HOME/.local/bin"
UNIT_DIR="$HOME/.config/systemd/user"
FILES=(bin/cpu-alert bin/cpu-alert-popup systemd/cpu-alert.service)

uninstall() {
    systemctl --user disable --now cpu-alert.service 2>/dev/null || true
    rm -f "$BIN/cpu-alert" "$BIN/cpu-alert-popup" "$UNIT_DIR/cpu-alert.service"
    systemctl --user daemon-reload
    echo "cpu-alert uninstalled."
}

# Prints a directory holding FILES: the clone itself, or a temp dir filled from GitHub.
source_dir() {
    local here
    here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
    if [[ -f "$here/bin/cpu-alert" ]]; then
        echo "$here"
        return
    fi
    local tmp
    tmp="$(mktemp -d)"
    for f in "${FILES[@]}"; do
        curl -fsSL --create-dirs -o "$tmp/$f" "$RAW_URL/$f"
    done
    echo "$tmp"
}

main() {
    if [[ "${1:-}" == "--uninstall" ]]; then
        uninstall
        return
    fi

    if ! python3 -c "import gi; gi.require_version('Gtk', '3.0')" 2>/dev/null; then
        echo "Missing GTK3 Python bindings. Install them with:" >&2
        echo "  sudo apt install python3-gi gir1.2-gtk-3.0" >&2
        exit 1
    fi

    local src
    src="$(source_dir)"
    install -Dm755 "$src/bin/cpu-alert" "$BIN/cpu-alert"
    install -Dm755 "$src/bin/cpu-alert-popup" "$BIN/cpu-alert-popup"
    install -Dm644 "$src/systemd/cpu-alert.service" "$UNIT_DIR/cpu-alert.service"

    systemctl --user daemon-reload
    systemctl --user enable cpu-alert.service
    systemctl --user restart cpu-alert.service

    echo "cpu-alert installed and running. Logs: journalctl --user -u cpu-alert -f"
}

main "$@"
