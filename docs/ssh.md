# SSH

Key-only login, no root, one allowed user per box.

## Clients

| Client | OS | Key |
|---|---|---|
| chadlab (M80q) | Linux Mint | `~/.ssh/id_ed25519` |
| Laptop | Windows | `%USERPROFILE%\.ssh\id_ed25519` |

Every client needs its **own** key on every server. Two clients means one dying doesn't lock you out.

### Generate a key (once per client)
```bash
ssh-keygen -t ed25519   # Enter through the prompts
```

### Copy it to a server

**Linux/macOS**
```bash
ssh-copy-id <user>@<ip>
```

**Windows (PowerShell, no `ssh-copy-id`)**
```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh <user>@<ip> "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

Test with `ssh <user>@<ip>`. It should log in with no password prompt.

The trailing comment on each line of `authorized_keys` (an email, `user@host`) is only a label. Edit it freely.

### Client config

Copy [`configs/ssh/config.example`](../configs/ssh/config.example) into `~/.ssh/config` (Windows: `C:\Users\<you>\.ssh\config`) and fill in the IPs. Then `ssh choppedlab` just works.

SSH sends your **local** username unless told otherwise, so the `User` line is required.

## Server hardening

**Only after every client's key works.** Once password login is off, new keys can't be copied over SSH.

Install [`configs/sshd/10-hardening.conf`](../configs/sshd/10-hardening.conf) with that box's user:
```bash
sudo tee /etc/ssh/sshd_config.d/10-hardening.conf > /dev/null <<'EOF'
PasswordAuthentication no
PermitRootLogin no
AllowUsers <user>
EOF
sudo sshd -t && sudo systemctl reload ssh
```

Use `sudo tee`, not `sudo cat >`. The redirect runs as your user and fails.

Verify the effective config:
```bash
sudo sshd -T | grep -Ei 'passwordauthentication|permitrootlogin|allowusers'
```

Keep the current session open and test a fresh login from **each** client before closing it.

### Adding a key after hardening
Use an existing session to re-enable passwords temporarily:
```bash
sudo mv /etc/ssh/sshd_config.d/10-hardening.conf /tmp/ && sudo systemctl reload ssh
# copy the new key, then:
sudo mv /tmp/10-hardening.conf /etc/ssh/sshd_config.d/ && sudo systemctl reload ssh
```

## Host key prompts

The first connection to a new IP asks you to trust the host key. Verify it on the server:
```bash
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

After a reflash, the Pi has new host keys. Clear the stale entry with:
```bash
ssh-keygen -R <ip>
```

## Pi-to-Pi

Not set up on purpose. The Pis don't need shell access to each other, and leaving it out stops one compromised box from reaching the other. Pi-hole sync (nebula-sync) uses the web API, not SSH.

## Exiting

`exit` or `Ctrl+D`. If the session is frozen: Enter, then `~.`.

## Client config: details

- Set up on the laptop (`C:\Users\<you>\.ssh\config`) and chadlab (`~/.ssh/config`), from [config.example](../configs/ssh/config.example).
- `Host *` defaults: `ServerAliveInterval 60` / `ServerAliveCountMax 3` keep idle sessions alive and disconnect cleanly instead of freezing.
- Linux: `chmod 600 ~/.ssh/config`. SSH refuses a config other users could edit.
- Windows: write the file from PowerShell, not Notepad. Notepad can save it as `config.txt`, which SSH ignores.
- Verify without connecting: `ssh -G <alias>` prints the final settings SSH would use.
- Aliases work for `scp`, `rsync`, git and VS Code Remote-SSH too.
- LAN IPs work remotely through the Tailscale subnet route (needs choppedlab up).
