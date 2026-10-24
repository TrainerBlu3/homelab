# Stress testing

Validates each board and its power supply under sustained load. Run it on both Pis before the charger return window closes (Nov 2).

## Run it

Use tmux so the test survives an SSH drop:
```bash
sudo apt install -y tmux stress-ng
tmux new -s stress
```

Pane 1 (or use [`scripts/stress-test.sh`](../scripts/stress-test.sh)):
```bash
stress-ng --cpu 6 --vm 2 --vm-bytes 75% --timeout 30m --metrics-brief
```

`Ctrl+b` `%` to split, then in pane 2:
```bash
watch -n 2 'cat /sys/class/thermal/thermal_zone*/temp; cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq'
```
Temperatures are millidegrees: `60000` = 60°C.

Detach with `Ctrl+b` `d`. Reattach with `tmux attach -t stress`.

## Pass criteria

- No crash or reboot across 30 minutes
- Temperature stays under ~80°C (cases upright, fins vertical, 1–2cm gap)
- Clocks don't sit pinned low for long stretches
- 5–10 cold power cycles (unplug, wait, replug) each boot cleanly

## If one fails

Suspect the charger first. Swap chargers between boards. If the failure follows the charger, return it. If it stays with the board, it's the board.

## Results

| Board | Date | Peak temp | Throttled? | Cold boots | Result |
|---|---|---|---|---|---|
| choppedlab | | | | /10 | |
| npclab | | | | /10 | |

## tmux cheat sheet

| Action | Keys |
|---|---|
| Split side-by-side | `Ctrl+b` `%` |
| Split top/bottom | `Ctrl+b` `"` |
| Switch pane | `Ctrl+b` arrow |
| Detach | `Ctrl+b` `d` |
| List sessions | `tmux ls` |
