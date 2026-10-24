# Stress testing

Validates each board and its power supply under sustained load, and checks that it recovers cleanly from power loss.

## Load test

Run in tmux so the test survives an SSH drop. **Paste one line at a time** (multi-line pastes into tmux can split across shells).
```bash
sudo apt install -y tmux stress-ng
tmux new -s stress
```
```bash
bash ~/stress-test.sh 30
```
Optional live view: `Ctrl+b` `%`, then `tail -f ~/stress-$(hostname)-*.log`.

`--vm-bytes 75%` takes 75% of memory *available at start*, so the load varies slightly between runs.

### Reading the results
```bash
LOG=$(ls -t ~/stress-*.log | head -1)
grep -o 'temp=[0-9]*' "$LOG" | cut -d= -f2 | sort -n | tail -1      # peak °C
awk -F'freq=' '{print $2}' "$LOG" | sort | uniq -c | sort -rn       # throttling
cat /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq           # real max clocks
```
Full speed on this board (**OP1** RK3399): **1512MHz** little ×4 / **2016MHz** big ×2. Always read the max clocks from the system rather than assuming them.

Thermal reference: idle 30–45°C · load 55–75°C normal · ~85°C throttle point.

## Cold-boot test

Rock Pis have a known intermittent U-Boot hang on power-up. The load test can't catch it.
1. `sudo poweroff`, wait for the LED to go off (protects the eMMC).
2. Unplug, wait 10s, replug.
3. After ~90s: SSH in, then check:
```bash
journalctl --list-boots | wc -l        # rises by 1 per boot
systemctl --failed
sudo journalctl -b -p err --no-pager | diff ~/baseline-errors.txt -
```
Boot *start* timestamps are unreliable: there's no RTC battery, so the clock resumes from the last shutdown until NTP syncs. Count boots instead.

## Results

| Board | Date | Placement | Peak | Throttled (big cores) | Stability |
|---|---|---|---|---|---|
| choppedlab | 2026-10-23 | Flat, on top of another device | 81°C | 0% | Pass |
| npclab | 2026-10-23 | Flat, on top of another device | 84°C | 5% (→1800MHz) | Pass |
| choppedlab | 2026-10-24 | Upright, cased | 85°C | 14% (→1800/1608MHz) | Pass |
| npclab | 2026-10-24 | Upright, cased | 85°C | 23% (→1800/1608MHz) | Pass |

Cold boots: choppedlab __/__ · npclab __/__ (target 3+ each before Nov 2)

### Conclusion
Both boards and both chargers are stable under 30 minutes of sustained 100% CPU + RAM load. The passive cases throttle lightly (one or two steps) at the 85°C limit. Upright placement made no measurable difference; ambient temperature and the closed case dominate, and npclab runs ~3°C hotter consistently (chip/heatsink variation).

**Decision:** the real workload (DNS, VPN) is near idle, so light throttling under synthetic load is accepted. Cases stay on for dust protection; filtered active airflow comes with the rack.
