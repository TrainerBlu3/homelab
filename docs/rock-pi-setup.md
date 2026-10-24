# Rock Pi 4B+ setup

Same process for both boards. Replace `<user>`, `<hostname>`, and `<ip>` per the table in the README.

## 1. OS choice

Use **Armbian Debian 13 Minimal (CLI)**. Armbian maintains current stable images for `rockpi-4bplus` on the 6.18 kernel. Avoid Radxa's vendor images, which are stale and have reported boot-stability issues.

Arch Linux ARM doesn't officially support this board, and a rolling release is a poor fit for a DNS box.

## 2. Flashing

**Option A: microSD, then eMMC (easiest)**
1. Flash Armbian to microSD (balenaEtcher or `dd`).
2. Boot from SD.
3. Run `armbian-install` and choose boot from eMMC.

The RK3399 boots from eMMC before SD. If an old bootloader on eMMC ignores the SD card, wipe it from the running OS:
```bash
lsblk                                            # the eMMC has boot0/boot1 partitions
sudo dd if=/dev/zero of=/dev/mmcblkX bs=1M count=32 && sync
```

**Option B: maskrom (no SD card)**
Use an A↔A cable to the upper USB 3.0 (OTG) port.
```bash
xz -d Armbian_*.img.xz
rkdeveloptool ld
rkdeveloptool db rk3399_loader_*.bin
rkdeveloptool wl 0 Armbian_*.img
rkdeveloptool rd
```

## 3. First boot

- Connect ethernet to the **main hub**, not the extender.
- Armbian's wizard sets the root password, creates a user, and sets the locale and timezone.
- If the wizard reports no internet, check the link lights or swap the cable. Wi-Fi works for setup, but run the box wired afterwards (see step 4).

Find the IP from the console:
```bash
hostname -I
```

## 4. Reserve the IP

Interfaces use predictable names, so ethernet is `end0`, not `eth0`.
```bash
ip -br link    # MAC addresses
ip -br addr    # IP addresses
```
1. Reboot once and confirm the `end0` MAC doesn't change.
2. In the Telus hub (`192.168.1.254`), go to **Network → LAN → LAN DHCP** and reserve that MAC.
3. Reboot and confirm with `ip -br addr`.

If Wi-Fi was used during setup, turn it off so the box doesn't hold two IPs:
```bash
sudo nmcli radio wifi off
```

## 5. Naming

```bash
OLD=$(hostname)
sudo hostnamectl set-hostname <hostname>
sudo hostnamectl set-hostname "<Hub Name>" --pretty
sudo sed -i "s/$OLD/<hostname>/g" /etc/hosts   # prevents sudo "unable to resolve host"
```
Then rename the device in the hub's device list to match the hub name.

## 6. User

Use the account from the first-boot wizard. Don't rename `root`.
```bash
id <user>                     # confirm 27(sudo) is listed
sudo usermod -aG sudo <user>  # if it isn't
```

## 7. Update

```bash
sudo apt update && sudo apt full-upgrade -y
```

## 8. SSH

See [ssh.md](ssh.md): copy keys from every client **before** applying the hardening file.

## 9. Go headless

Log out of the console (`exit`) and unplug HDMI. Manage everything over SSH from here on.
