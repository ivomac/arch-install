# AGENTS.md

## Overview

This repository automates the reproduction of a complete Arch Linux setup: partitioning, base install, system configuration, dotfiles, AUR packages, and graphical environment. It is a **multi-phase, orchestrated collection of shell scripts** — not a single monolithic installer.

Key stack: Zsh, Wayland (Niri compositor), systemd-boot, pipewire, yay (AUR), greetd (autologin).

---

## Repository Map

```
arch_install/
├── install.sh               # Single entry point — subcommand dispatcher
├── scripts/
│   ├── nvme.py              # NVMe drive LBA format recommender (pre-install)
│   ├── base.sh               # Pacstrap + genfstab (from ISO)
│   ├── root.sh              # All root-level system configuration (inside chroot)
│   ├── pacman.sh            # Pacman.conf + pacman.txt package install (sourced by root.sh)
│   ├── user.sh              # User setup: SSH, GPG, dotfiles, greetd, services (inside chroot)
│   ├── aur.sh               # AUR helper install + AUR packages + Rust (inside chroot)
│   ├── graphical.sh         # Post-reboot graphical app config (after first boot)
│   ├── services.sh          # Push/pull systemd service state (utility)
│   └── update-pkgs.sh       # Push/pull package list state (maintenance utility)
├── pkgs/
│   ├── pacman.txt           # official Arch packages (one per line)
│   ├── aur.txt              # AUR packages (one per line)
│   ├── services-system.txt  # system-level systemd units (one per line)
│   └── services-user.txt    # user-level systemd units (one per line)
└── config/
    ├── qBittorrent.conf     # Template with TORRENTROOT and HOME placeholders
    └── syncthing.xml        # Syncthing configuration (copied verbatim)
```

---

## Architecture

### Orchestrator Pattern

`install.sh` is the **sole entry point**. It dispatches to scripts based on a subcommand argument. Every subcommand represents a **phase** that must run in strict linear order.

```
install.sh nvme       →  python scripts/nvme.py
install.sh base       →  [from ISO] source base.sh
install.sh root       →  [inside chroot, as root] source root.sh
install.sh user       →  [inside chroot, as user]  source user.sh; source aur.sh; zsh
install.sh graphical  →  [post-reboot, as user]    source graphical.sh; cat TODO.md
```

Without arguments, `install.sh` prints `README.md` and exits.

### Source vs. Subprocess

Scripts invoked by `install.sh` are **sourced** (not executed as subprocesses), so environment variables propagate:

```zsh
# install.sh sets these before sourcing:
ROOT  →  repo root directory
SCRIPTS → $ROOT/scripts
CONFIG → $ROOT/config
PKGS   → $ROOT/pkgs
USER   →  current user (set by `su` in chroot, or login on running system)
```

The exception is `services.sh`, which is **called as a subprocess** (it is Bash, not Zsh, and locates the pkgs directory by resolving its own path).

### Phase Ordering

Each phase has strict prerequisites:

| Phase | Prerequisites | Context |
|-------|--------------|---------|
| `nvme` | None (run from live ISO) | Bare metal |
| `base` | Disk partitioned, /mnt mounted | Live ISO, pacstrap + copy repo + base config |
| `root` | Repo copied in, arch-chroot /mnt | Inside chroot, as root |
| `user` | root phase complete, SSH keys manually copied | Inside chroot, as regular user |
| `graphical` | Rebooted into new system, WiFi connected | Running system, as user |

---

## Shell Conventions

### Zsh (primary)

Most scripts (`install.sh`, `pacman.sh`, `root.sh`, `user.sh`, `aur.sh`, `graphical.sh`, `update-pkgs.sh`) are Zsh.

```zsh
#!/usr/bin/env zsh
setopt errexit nounset pipefail no_nomatch err_return noclobber
```

- **`errexit`**: Exit on any command failure.
- **`nounset`**: Error on unset variable references.
- **`pipefail`**: Pipeline fails if any component fails.
- **`no_nomatch`**: Allow globs that match nothing to expand to an empty list (used in `userhomes=(/home/*)`)
- **`noclobber`**: Prevent accidental file overwrite in user.sh context. Use `>|` to force-overwrite.
- **`err_return`**: Return from a function/trap on error.

### Bash

Only `services.sh` uses Bash:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

It resolves the `pkgs/` directory by walking relative to its own path (since it's called as a subprocess, it can't rely on `$ROOT`/`$PKGS` being set).

### File Write Pattern

All config files use `>|` (force overwrite, overriding noclobber):

```zsh
echo "content" >|"/etc/pacman.conf"
```

### Section Headers

Scripts use `## SECTION NAME` as visual separators between logical blocks. No inline comments; the section header describes everything that follows.

### Echo for Progress

Scripts use `echo "..."` for progress indication. Each script announces what it's doing before performing destructive actions.

---

## Data Flow

### User Discovery

The `root` phase discovers users by globbing:

```zsh
userhomes=(/home/*)        # inside chroot (root phase)
userhomes=(/mnt/home/*)    # outside chroot (base phase)
```

For each user home, `USER` is derived from the directory name:

```zsh
USER="${HOME:A:t}"
```

The `user` and `graphical` phases expect `$USER` to already be set (via `su (user)` or initial login).

### Variable Chain

`install.sh` → sets `$ROOT`, `$SCRIPTS`, `$CONFIG`, `$PKGS`, `$USER`, `$HOME` → sources scripts that reference these variables. Scripts never hardcode paths outside the repo.

### `services.sh` Path Resolution

Since `services.sh` is called as a subprocess (not sourced), it resolves `pkgs/` by walking up from its own location:

```bash
PKGS="$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]:-$0}")")")/pkgs"
```

---

## Package & Service Management

### Package Lists

Three separate lists define the system's package state:

| File | Source | Installed by |
|------|--------|-------------|
| `pkgs/pacman.txt` | `install.sh root` | `pacman -S --asexplicit - < pkgs/pacman.txt` |
| `pkgs/aur.txt` | `install.sh user` | `yay -S --asexplicit - < pkgs/aur.txt` |

The `--asexplicit` flag is critical: it marks packages as explicitly installed (not dependencies), so they won't be auto-removed.

`update-pkgs.sh push` snapshots the current native + foreign package state. `update-pkgs.sh pull` restores it (and removes packages not in the lists).

### Service Lists

`services.sh` manages systemd unit state declaratively:

- **`push`**: Snapshots currently-enabled systemd units (excluding services that have a corresponding socket) into `pkgs/services-{system,user}.txt`.
- **`pull`**: Enables every service in the list, **then disables any enabled service not in the list** — the system is forced to match the declared state exactly.

Service push uses `--type=service,timer,socket` and filters out services that have an active socket unit (socket activation is preferred over explicit service enablement).

---

## Configuration Model

### Template Substitution

`config/qBittorrent.conf` contains `TORRENTROOT` and `HOME` placeholders. `graphical.sh` prompts for the torrent root and runs:

```zsh
sed -e "s:TORRENTROOT:$TORRENTROOT:g" -e "s:HOME:$HOME:g" <template >output
```

### Verbose Copies

`syncthing.xml` is copied verbatim to `~/.local/state/syncthing/config.xml`.

---

## Key Behaviors

### Idempotency

Scripts are designed for **fresh installs**, not repeated runs. Some operations have guards:

- `root.sh`: Checks `[[ ! -s /var/lib/postgres/data/PG_VERSION ]]` before initdb
- `user.sh`: Checks `[ -d "$HOME/.ssh" ]` and exits if missing
- `services.sh`: Skips already-enabled services with `[skip]` output

But most operations **unconditionally overwrite files**. Running a phase twice can break things.

### Interactive Prompts

- `root.sh`: Auto-detect GPU (amd/intel) via lspci
- `user.sh`: Interactive SSH passphrase input (typed into a plaintext file, deleted at end)
- `graphical.sh`: Multiple interactive steps (bluetooth pairing, fstab editing, firefox logins, torrent root prompt)

### Security Tradeoffs

- SSH key passphrase is **temporarily written to a plaintext file** (`ssh_askpass.sh`) and deleted at the end of `user.sh`. The passphrase is still visible in process listings during execution.
- GPG private key (`pass.key`) is cloned from a private GitHub repo.
- The Syncthing config contains an API key. **Never commit a `syncthing.xml` with real device/folder IDs.**

### Compositor

The setup uses **Niri** (scrolling-tiling Wayland compositor), not GNOME, KDE, Sway, or Hyprland. X11 is explicitly removed in `graphical.sh` (`pacman -Rs xorg-server`). XWayland apps run via `xwayland-satellite`.

---

## How to Add or Modify

### Adding an Official Package

1. Add the package name to `pkgs/pacman.txt` (one per line, sorted).
2. The `root` phase reads this file automatically.

Alternatively: install it manually, then run `./scripts/update-pkgs.sh push` to snapshot the current state.

### Adding an AUR Package

1. Add the package name to `pkgs/aur.txt`.
2. The `user` phase installs AUR packages via `yay`.

### Adding a Systemd Service

1. Add the unit name to `pkgs/services-system.txt` or `pkgs/services-user.txt`.
2. Ensure the corresponding package is in the package lists.
3. The `root` or `user` phase calls `services.sh --system pull` / `--user pull` which enables all listed services and disables unlisted ones.

Alternatively: enable it with `systemctl enable`, then run `services.sh --system push` to snapshot.

### Adding a New Phase

1. Add a new `case` branch in `install.sh`.
2. Create the script in `scripts/`.
3. If it should run in the chroot as user, follow the pattern of `user` (source scripts, drop into zsh).
4. If it's post-reboot, follow the `graphical` pattern (echo progress, cat TODO.md at end).

### Modifying Boot Parameters

Boot cmdline is in `root.sh` lines 30-31. The script reads an existing .conf from `/boot/loader/entries/`, modifies it, and writes `arch.conf`.

### Modifying System Configuration

Most system config is in `root.sh`: mkinitcpio hooks, sudoers, sysctl (swappiness, printk), vconsole, reflector, fstab, udev rules, shutdown timeout, zram, sleep, postgres. greetd autologin is in `user.sh`.

---

## Gotchas

### `aur-helper-install` Binary

`aur.sh` line 9 calls `zsh "$HOME/.local/bin/aur-helper-install" -f yay`. This is a **custom binary/script that must exist in the user's dotfiles before this phase runs**. It is not part of this repo.

### SSH Keys

`user.sh` requires SSH keys to exist before it runs. The README documents a manual step: `cp ssh-keys/* /home/(user)/.ssh/`. The script exits with an error if `~/.ssh` doesn't exist.

### Multi-User Loop

The `root` phase loops over all `/home/*` directories. If there are stale home directories, they will also be processed. The `user` phase assumes a single user (`$USER`).

### Chroot Context

The `root` and `user` phases MUST run inside `arch-chroot /mnt`. Variables behave differently in a chroot (e.g., home directories are at `/home/*`, not `/mnt/home/*`).

### Service Idempotency

`services.sh pull` is aggressive: it **disables** any enabled service not in the list. If you manually enable a service post-install, it will be re-disabled on a subsequent pull. Use `push` to capture changes before running `pull` again.

### `noclobber` and `>|`

Scripts use `>|` (not `>`) to write files. This is intentional: it overrides Zsh's `noclobber` option. If you add new file writes, use `>|` for consistency.

### No Comments

The codebase has no comments. Section headers (`## SECTION NAME`) are the only organizational markers. Don't add comments unless asked.

### Package Flags

Packages are installed with `--asexplicit` to prevent pacman from treating them as orphans. If you modify package installation, maintain this flag.

---

## Verification

### Testing Changes

There is no test suite. To validate changes:

1. **Sourcing chain**: Verify that `install.sh` sources the correct scripts and that variables propagate correctly.
2. **Package lists**: Check that packages in `pkgs/pacman.txt` and `pkgs/aur.txt` exist in the Arch repos / AUR.
3. **Service lists**: Check that services in `pkgs/services-*.txt` correspond to installed packages.
4. **Shell syntax**: Run `zsh -n` on each script to check for syntax errors.
5. **ShellCheck**: Run `shellcheck` on the Bash script (`services.sh`) and consider it for Zsh scripts.

### Dry-Run Strategy

Most operations have clear effects. To test a single script in isolation:
1. Comment out the destructive parts.
2. Source the script in a shell where `$ROOT`, `$SCRIPTS`, `$CONFIG`, `$PKGS`, `$USER`, `$HOME` are set.
3. Observe the echo output and file writes.

### Manual Installation Flow Testing

The only complete test is a full install run, documented in `README.md`:
```
iwctl station wlan0 connect (SSID)
curl -L https://github.com/ivomac/arch-install/archive/refs/heads/main.tar.gz | tar -xzv
cd arch-install-main
./install.sh nvme
./install.sh base (user)
arch-chroot /mnt
./install.sh root <hostname>
su (user)
cd /home/(user)/arch-install
cp ssh-keys/* /home/(user)/.ssh/
./install.sh user
reboot
nmcli device wifi connect (SSID) password (pass)
./install.sh graphical
```
