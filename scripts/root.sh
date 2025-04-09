
# SU SETUP

## BOOT

ori_file=$(ls /boot/loader/entries/*linux.conf)
ori_content=$(cat "$ori_file" | sed -e 's/title.*/title   Arch Linux/')

echo "$ori_content fbcon=font:TER16x32 video=1920x1080@60 sysrq_always_enabled=1 acpi_enforce_resources=lax nowatchdog nmi_watchdog=0 modprobe.blacklist=iTCO_wdt,sp5100_tco sysctl.vm.swappiness=35 quiet loglevel=3 udev.log_level=3 rd.udev.log_level=3 systemd.show_status=auto
" > "/boot/loader/entries/arch.conf"

echo "default arch.conf
timeout 0
console-mode keep
" > "/boot/loader/loader.conf"

## SUDOERS

echo "Setting up sudoers"

echo "
Defaults targetpw
ALL ALL=(ALL:ALL) ALL
" > /etc/sudoers.d/40-targetpw

## ACTIVATE SysRq

echo "Activating SysRq"

echo "kernel.sysrq=256" > /etc/sysctl.d/40-sysrq.conf

## QUIET

echo "Quieting kernel"

echo "kernel.printk=3 3 3 3" > /etc/sysctl.d/40-quiet.conf

## CHANGE SHUTDOWN TIMEOUT

echo "Changing shutdown timeout"

timeout="
[Manager]
DefaultTimeoutStartSec=5s
DefaultTimeoutStopSec=5s
DefaultTimeoutAbortSec=5s
DefaultDeviceTimeoutSec=5s
"

mkdir -p /etc/systemd/system.conf.d
mkdir -p /etc/systemd/user.conf.d

echo "$timeout" > /etc/systemd/system.conf.d/40-shutdown.conf
echo "$timeout" > /etc/systemd/user.conf.d/40-shutdown.conf

## ZSH HOME

echo "Setting ZSH home"

mkdir -p /etc/zsh

echo 'export ZDOTDIR=$HOME/.config/zsh' > /etc/zsh/zshenv

## SDDM WAYLAND

echo "Setting up SDDM for KDE Wayland"

mkdir -p /etc/sddm.conf.d

echo "
[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
Numlock=off
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1 --inputmethod maliit-keyboard
" > /etc/sddm.conf.d/40-kde.conf

echo "
[Theme]
Current=breeze
CursorTheme=breeze_cursors
EnableAvatars=true
Font=Fira Mono Medium,11,-1,5,500,0,0,0,0,0,0,0,0,0,0,1,Regular
" > /etc/sddm.conf.d/40-theme.conf

echo "
[Users]
MaximumUid=60513
MinimumUid=1000

[Autologin]
Session=plasma
User=
" > /etc/sddm.conf.d/40-autologin.conf

echo "Add user to /etc/sddm.conf.d/40-autologin.conf if you want to enable autologin"

## SLEEP

echo "Setting up sleep"

mkdir -p /etc/systemd/sleep.conf.d

echo "
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowHybridSleep=no
AllowSuspendThenHibernate=no
" > /etc/systemd/sleep.conf.d/40-disable-suspend.conf

## FSTAB

sed -i 's/	rw,relatime	/	rw,noatime,commit=60	/' /etc/fstab

## SYSTEM

echo "Setting up system services"

systemctl enable bluetooth.service
systemctl enable earlyoom.service
systemctl enable docker.service
systemctl enable fstrim.timer
systemctl enable sshd.service
systemctl enable tailscaled.service
