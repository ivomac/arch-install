#!/usr/bin/env zsh

echo "System configuration"

if ! systemd-detect-virt --chroot &> /dev/null; then
  echo "Error: must run inside arch-chroot /mnt"
  exit 1
fi

## TIMEZONE

ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
hwclock --systohc

## LOCALE

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >| /etc/locale.conf

## VCONSOLE

echo "KEYMAP=us
FONT=ter-u18n
XKBLAYOUT=us
XKBMODEL=pc105+inet
XKBOPTIONS=terminate:ctrl_alt_bksp
" >| /etc/vconsole.conf

## NETWORK

echo "$HOSTNAME" >| /etc/hostname

cat >| /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

echo "Enabling base services"
systemctl enable NetworkManager.service
systemctl enable systemd-timesyncd.service

## PACMAN

source "$SCRIPTS/pacman.sh"

## GPU DETECTION

if lspci | grep -qiE 'vga.*amd|vga.*radeon|3d.*amd|3d.*radeon'; then
  echo "Detected AMD GPU"
  VIDEO_DRIVER="amdgpu"
  VIDEO_BOOT_OPTS=""
else
  echo "Detected Intel GPU"
  VIDEO_DRIVER="i915"
  VIDEO_BOOT_OPTS=""
fi

## MKINITCPIO

echo "Setting up mkinitcpio"

echo "MODULES=($VIDEO_DRIVER)
BINARIES=()
FILES=()
HOOKS=(systemd microcode autodetect modconf kms sd-vconsole block filesystems fsck)
" >| /etc/mkinitcpio.conf

echo "Running mkinitcpio"
mkinitcpio -P

## ROOT PASSWORD

echo "Set root password:"
passwd

## USER

userhomes=(/home/*(N))
((${#userhomes} > 0))
BASE_USER="${userhomes[1]:A:t}"

echo "Set password for $BASE_USER:"
passwd "$BASE_USER"

usermod -a -G wheel,video "$BASE_USER"
chown -R "$BASE_USER:$BASE_USER" "/home/$BASE_USER"

## BOOTLOADER

echo "Installing systemd-boot"
bootctl install

ROOT_PARTUUID=$(findmnt -no PARTUUID /)

cat >| /boot/loader/entries/arch.conf << EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=${ROOT_PARTUUID} rw fbcon=font:TER16x32 sysrq_always_enabled=1 nowatchdog nmi_watchdog=0 modprobe.blacklist=iTCO_wdt,sp5100_tco sysctl.vm.swappiness=35 splash loglevel=3 udev.log_level=3 rd.udev.log_level=3 systemd.show_status=auto rootflags=noatime ${VIDEO_BOOT_OPTS}
EOF

echo "default arch.conf
timeout 0
console-mode keep
" >| "/boot/loader/loader.conf"

## SUDOERS

echo "Setting up sudoers"

echo "Defaults rootpw
ALL ALL=(ALL:ALL) ALL
" >| /etc/sudoers.d/40-rootpw

visudo -cf /etc/sudoers.d/40-rootpw

## QUIET

echo "Quieting kernel"

echo "kernel.printk=3 3 3 3" >| /etc/sysctl.d/40-quiet.conf

## CHANGE SHUTDOWN TIMEOUT

echo "Changing shutdown timeout"

timeout="[Manager]
DefaultTimeoutStartSec=5s
DefaultTimeoutStopSec=5s
DefaultTimeoutAbortSec=5s
DefaultDeviceTimeoutSec=5s
"

mkdir -p /etc/systemd/system.conf.d
mkdir -p /etc/systemd/user.conf.d

echo "$timeout" >| /etc/systemd/system.conf.d/40-shutdown.conf
echo "$timeout" >| /etc/systemd/user.conf.d/40-shutdown.conf

## REFLECTOR

echo "Setting up reflector timer"

cat >| /etc/systemd/system/reflector-by-rate.service << 'EOF'
[Unit]
Description=Refresh mirrorlist sorted by download rate
Wants=network-online.target
After=network-online.target nss-lookup.target

[Service]
Type=oneshot
ExecStart=/usr/bin/reflector --latest 5 --protocol https --age 12 --sort rate --download-timeout 12 --save /etc/pacman.d/mirrorlist
EOF

cat >| /etc/systemd/system/reflector-by-rate.timer << 'EOF'
[Unit]
Description=Refresh mirrorlist weekly by rate

[Timer]
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=12h

[Install]
WantedBy=timers.target
EOF

## ZSH HOME

echo "Setting ZSH home"

mkdir -p /etc/zsh

echo "export ZDOTDIR=\$HOME/.config/zsh" >| /etc/zsh/zshenv

## DISPLAY

mkdir -p /etc/modules-load.d
mkdir -p /etc/modprobe.d

cat >| /etc/modules-load.d/40-display.conf << 'EOF'
i2c_dev
ddcci
ddcci_backlight
EOF

cat >| /etc/modprobe.d/40-display.conf << 'EOF'
options ddcci autoprobe_addrs=1
options ddcci_backlight autoprobe_addrs=1
EOF

## SLEEP

echo "Setting up sleep"

mkdir -p /etc/systemd/sleep.conf.d

echo "[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowHybridSleep=no
AllowSuspendThenHibernate=no
" >| /etc/systemd/sleep.conf.d/40-disable-suspend.conf

## FSTAB

sed -i '/[[:space:]]ext4[[:space:]]/s/rw,relatime/rw,noatime,commit=60/' /etc/fstab

## ZRAM

cat >| /etc/systemd/zram-generator.conf << 'EOF'
[zram0]
zram-size = ram / 4
compression-algorithm = zstd
EOF

## KEYBOARD VIAL

echo '
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="video", TAG+="uaccess", TAG+="udev-acl"
' >| /etc/udev/rules.d/99-vial.rules

## STEAM

echo '[Desktop Entry]
Name=Steam
Comment=Application for managing and playing games on Steam
Exec=/usr/bin/steam %U
Terminal=false
Type=Application
Hidden=true
NoDisplay=true
' >| /usr/share/applications/steam.desktop
chattr -i /usr/share/applications/steam.desktop 2> /dev/null || true

chattr +i /usr/share/applications/steam.desktop

## POSTGRES

if [[ ! -s /var/lib/postgres/data/PG_VERSION ]]; then
  su - postgres -c "initdb -D /var/lib/postgres/data"
fi

## SYSTEM

echo "Setting up system services"

"$SCRIPTS/services.sh" --system pull
