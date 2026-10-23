# cpu-mem-alert

A small Linux desktop monitor that pops up an alert when CPU or memory usage stays high.

![popup](screenshot.png)

- Two columns: **Processor** (usage + top 5 processes by CPU) and **Memory** (usage, GiB used + top 5 processes by RAM).
- Each value is green below the threshold, orange above it, and **red at 95%+**. The border takes the worst color.
- An alert fires after usage stays above the threshold for 3 samples in a row, then waits 5 minutes before alerting again.
- The popup sits in the top-right corner, closes on click, and disappears after 15 seconds.
- **Show programs to close** opens a list of your heaviest processes (live CPU + memory). Tick some and press
  **Close selected** (asks them to quit) or **Force kill** (stops them immediately). The **Details** column says what
  each process is: the project a Claude Code / Junie / dev tool runs in, the Docker container, or the role of a
  Chrome/Electron process (tab, extension, GPU…). Chrome does not reveal which tab a process belongs to; press
  Shift+Esc in Chrome for that. Hover a row for the full command and folder. Only your own processes are
  listed; root processes, core desktop processes and FortiClient are never shown. Open it any time with
  `cpu-alert-popup --candidates`.

## Requirements

- Linux with a graphical session and systemd (tested on Ubuntu 22.04, GNOME on Wayland)
- Python 3 with GTK3 bindings: `sudo apt install python3-gi gir1.2-gtk-3.0`
- XWayland when running on Wayland (enabled by default on GNOME)

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/hbenabdallah/cpu-mem-alert/main/install.sh | bash
```

Or from a clone:

```bash
git clone https://github.com/hbenabdallah/cpu-mem-alert.git
cd cpu-mem-alert
./install.sh
```

This copies the scripts to `~/.local/bin`, installs a systemd user service, and starts it. No root needed.

Uninstall:

```bash
curl -fsSL https://raw.githubusercontent.com/hbenabdallah/cpu-mem-alert/main/install.sh | bash -s -- --uninstall
```

(or `./install.sh --uninstall` from a clone)

## Test the popup

```bash
~/.local/bin/cpu-alert-popup 97 75 $'97.0%\tphp' 82 75 $'3.2G\tphpstorm' "26 / 31 GiB used"
```

## Configuration

Set these environment variables in the service (`systemctl --user edit cpu-alert`, then add `Environment=NAME=value` under `[Service]`):

| Variable | Default | Meaning |
| --- | --- | --- |
| `CPU_ALERT_THRESHOLD` | 75 | CPU % that counts as high |
| `MEM_ALERT_THRESHOLD` | 75 | Memory % that counts as high |
| `CPU_ALERT_CRITICAL` | 95 | % at which the popup turns red |
| `CPU_ALERT_INTERVAL` | 5 | Seconds between samples |
| `CPU_ALERT_SUSTAIN` | 3 | High samples in a row before alerting |
| `CPU_ALERT_COOLDOWN` | 300 | Seconds between two alerts |
| `CPU_ALERT_POPUP_TIMEOUT` | 15 | Seconds the popup stays on screen |

Logs: `journalctl --user -u cpu-alert -f`
