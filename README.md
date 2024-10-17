## Arch Linux installation

Backup:
  * data
  * firefox tabs
  * sidebery settings
  * kde window rules

```bash
iwctl station wlan0 connect "$SSID"
curl -L https://github.com/ivomac/arch-install/archive/refs/tags/latest.tar.gz | tar -xzv
cd arch-install-latest
./install.sh noipv6 (optional)
./install.sh nvme
```

Further nvme actions...

```bash
./install.sh base
./install.sh relocate (user)
arch-chroot /mnt/archinstall (or reboot)
./install.sh own (user)
```

```bash
cd /home/(user)/arch-install
./install.sh uninstall
./install.sh pkgs
./install.sh root
./install.sh noipv6 (optional)
su (user)
```

Add ssh keys...

```bash
./install.sh user
./install.sh yay
./install.sh aur
```

Restart...

```bash
./install.sh post-reboot
./install.sh manual
./install.sh todo
```

