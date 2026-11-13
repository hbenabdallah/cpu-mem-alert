# cpu-mem-alert

A small Linux desktop monitor that pops up an alert when CPU or memory usage stays high, or when a program eats too much of
your internet connection, and helps you find and close the programs causing it.

## Alert popup

![popup](screenshot.png)

- Three columns: **Processor** (usage + top 5 processes by CPU), **Memory** (usage, GiB used + top 5 processes by RAM)
  and **Internet** (how full the connection is + the programs over the per-program limit).
- Each value is green below the threshold, orange above it, and **red at 95%+**. The border takes the worst color.
- An alert fires after usage stays above the threshold for 3 samples in a row, then waits 5 minutes before alerting again.

## Internet limit that follows your connection

The per-program limit is a share of your internet speed, not a fixed number: with the default 10%, a 12 MB/s connection
alerts on any program using more than 1.2 MB/s, a 100 MB/s one only above 10 MB/s. Download and upload are checked
separately.

- The speed is **learned**: the monitor remembers the fastest download and upload rates it has seen (stored in
  `~/.cache/cpu-alert/net-speed`). Run a speed test once after installing so it knows your real speed right away.
- Or set it yourself with `NET_ALERT_SPEED` / `NET_ALERT_UPLOAD_SPEED` (MB/s), e.g. on a connection you rarely fill.
- The limit never goes below 512 KB/s, so a slow or not-yet-learned speed doesn't flood you with alerts.
- Traffic is counted per program from its TCP connections (`ss`, no root needed). Traffic it cannot attribute shows as
  its own row: `chrome (QUIC?)` when a program talks QUIC (UDP, used by Chrome for Google and YouTube), otherwise
  `unidentified` (e.g. Docker containers, other users).
- The popup sits in the top-right corner, closes on click, and disappears after 15 seconds.

## Programs to close

Click **Show programs to close** in the popup to see what is weighing on your machine and free it up in a few clicks.

![programs to close](process-list.png)

- Lists your 15 heaviest processes right now, ranked by live CPU + memory + share of the internet speed.
- The **Details** column says what each process actually is:
  - Claude Code, Junie or any dev tool: the **project** it runs in
  - Processes inside Docker: the **container** name
  - Chrome / Electron apps: the **role** of the process (tab, extension, GPU, network, main process…)
  - IDEs and their helpers (e.g. PhpStorm's AI semantic search index)
- Hover a row for the full command and folder.
- Tick processes, then **Close selected** (asks them to quit cleanly) or **Force kill** (stops them immediately, may
  lose unsaved work). The list refreshes on its own afterwards.
- Safe by design: only your own processes are listed. Root processes (security agents, system services), core desktop
  processes (GNOME Shell, audio…), FortiClient and the monitor itself are never shown.
- Chrome does not reveal which tab a process belongs to; press **Shift+Esc** in Chrome to see that.

Open it any time, without waiting for an alert:

```bash
cpu-alert-popup --candidates
```

## Requirements

- Linux with a graphical session and systemd (tested on Ubuntu 22.04, GNOME on Wayland)
- `ss` from iproute2 (installed by default)
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

## Test it

Show the popup with sample values:

```bash
~/.local/bin/cpu-alert-popup 97 75 $'97.0%\tphp' 82 75 $'3.2G\tphpstorm' "26 / 31 GiB used" \
    80 $'↓2.1M\tchrome' $'↓9.6 ↑0.2 of ~12.0 / 1.5 MB/s\nlimit ↓1.2 ↑0.5 MB/s per program'
```

Check which programs are over a given limit right now (bytes/s for download and upload):

```bash
~/.local/bin/cpu-alert-popup --net-procs 1000000 500000
```

Or trigger a real alert: run a quick monitor in one terminal and load every core in another.

```bash
CPU_ALERT_SUSTAIN=1 CPU_ALERT_COOLDOWN=30 ~/.local/bin/cpu-alert     # terminal A
for i in $(seq $(nproc)); do yes > /dev/null & done                  # terminal B
```

A red popup appears within a few seconds; open **Show programs to close**, tick the `yes` processes and close them
(or run `pkill yes`).

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
| `NET_ALERT_PERCENT` | 10 | Share of the internet speed one program may use |
| `NET_ALERT_MIN_KB` | 512 | Per-program limit never goes below this (KB/s) |
| `NET_ALERT_SPEED` | learned | Download speed in MB/s, instead of the fastest rate seen |
| `NET_ALERT_UPLOAD_SPEED` | learned | Upload speed in MB/s, instead of the fastest rate seen |

Logs: `journalctl --user -u cpu-alert -f`
