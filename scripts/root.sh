
# SU SETUP

## BOOT

ori_file=(/boot/loader/entries/*_linux.conf)
ori_content=$(sed -e 's/title.*/title   Arch Linux/' <"${ori_file[1]}")

echo "$ori_content fbcon=font:TER16x32 video=1920x1080@60 sysrq_always_enabled=1 acpi_enforce_resources=lax nowatchdog nmi_watchdog=0 modprobe.blacklist=iTCO_wdt,sp5100_tco sysctl.vm.swappiness=35 splash quiet loglevel=3 udev.log_level=3 rd.udev.log_level=3 systemd.show_status=auto
" >|"/boot/loader/entries/arch.conf"

echo "default arch.conf
timeout 0
console-mode keep
" >|"/boot/loader/loader.conf"

## MKINITCPIO

echo "Setting up mkinitcpio"

while [ "$user_input" != "amd" ] && [ "$user_input" != "intel" ]; do
  read -r -p "Enter GPU type (amd, intel): " user_input
done

case $user_input in
amd)
  VIDEO_DRIVER="amdgpu"
  ;;
intel)
  VIDEO_DRIVER="i915"
  ;;
esac

echo "MODULES=($VIDEO_DRIVER)
BINARIES=()
FILES=()
HOOKS=(systemd microcode autodetect modconf kms sd-vconsole block filesystems fsck)
" >|/etc/mkinitcpio.conf

echo "Running mkinitcpio"
mkinitcpio -P

## SUDOERS

echo "Setting up sudoers"

echo "
Defaults targetpw
ALL ALL=(ALL:ALL) ALL
" >|/etc/sudoers.d/40-targetpw

## ACTIVATE SysRq

echo "Activating SysRq"

echo "kernel.sysrq=256" >|/etc/sysctl.d/40-sysrq.conf

## QUIET

echo "Quieting kernel"

echo "kernel.printk=3 3 3 3" >|/etc/sysctl.d/40-quiet.conf

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

echo "$timeout" >|/etc/systemd/system.conf.d/40-shutdown.conf
echo "$timeout" >|/etc/systemd/user.conf.d/40-shutdown.conf

## ZSH HOME

echo "Setting ZSH home"

mkdir -p /etc/zsh

echo "export ZDOTDIR=\$HOME/.config/zsh" >|/etc/zsh/zshenv

## DISPLAY

mkdir -p /etc/modules-load.d

echo '''
i2c_dev
ddcci autoprobe_addrs
ddcci_backlight autoprobe_addrs
''' >|/etc/modules-load.d/40-display.conf

## SLEEP

echo "Setting up sleep"

mkdir -p /etc/systemd/sleep.conf.d

echo "
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowHybridSleep=no
AllowSuspendThenHibernate=no
" >|/etc/systemd/sleep.conf.d/40-disable-suspend.conf

## FSTAB

sed -i 's/  rw,relatime / rw,noatime,commit=60  /' /etc/fstab

## SYSTEM

echo "Setting up system services"

systemctl enable reflector.timer
systemctl enable fstrim.timer

systemctl enable docker.socket

systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable earlyoom.service
systemctl enable greetd.service
systemctl enable power-profiles-daemon.service
systemctl enable sshd.service
systemctl enable tailscaled.service
systemctl enable udisks2.service
