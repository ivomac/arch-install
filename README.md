## Arch Linux installation

Backup:
  * data
  * firefox tabs
  * sidebery settings

```bash
iwctl station wlan0 connect "$SSID"
curl -L https://github.com/ivomac/arch-install/archive/refs/tags/latest.tar.gz | tar -xzv
cd arch-install-latest
./install.sh nvme
./install.sh base
./install.sh relocate (user)
arch-chroot /mnt/archinstall
cd /home/(user)/arch-install
./install.sh own (user)
./install.sh uninstall
./install.sh pkgs
./install.sh root
cp ?/ssh-keys/* ~/.ssh/
su (user)
./install.sh user
./install.sh paru
reboot
./install.sh post-reboot
./install.sh manual
./install.sh todo
```

