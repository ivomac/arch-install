## Arch Linux installation

Backup:
  * Media
  * Docs
  * firefox tabs

```bash
iwctl station wlan0 connect "$SSID"
curl -L https://github.com/ivomac/arch-install/archive/refs/tags/latest.tar.gz | tar -xzv
cd arch-install-latest
./install.sh nvme
./install.sh base
./install.sh relocate (user)
arch-chroot /mnt
cd /home/(user)/arch-install
./install.sh root (user)
cp ssh-keys/* ~/.ssh/
su (user)
./install.sh user (user)
reboot
./install.sh graphical
./install.sh manual
./install.sh todo
```

