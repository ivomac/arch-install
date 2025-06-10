## Arch Linux installation

Backup:
  * Media
  * Docs

```bash
iwctl station wlan0 connect (SSID)
curl -L https://github.com/ivomac/arch-install/archive/refs/tags/latest.tar.gz | tar -xzv
cd arch-install
./install.sh nvme
./install.sh base
./install.sh relocate
arch-chroot /mnt
./install.sh root
su (user)
cd /home/(user)/arch-install
cp ssh-keys/* /home/(user)/.ssh/
./install.sh user
reboot
./install.sh manual
```

