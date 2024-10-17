#!/usr/bin/env zsh

setopt errexit nounset pipefail no_nomatch err_return noclobber

## BOOT MODE

fw_size=$(cat /sys/firmware/efi/fw_platform_size 2> /dev/null || true)
if [[ "$fw_size" != "64" ]]; then
  echo "Error: system must be booted in UEFI 64-bit mode"
  exit 1
fi
echo "Boot mode: UEFI 64-bit"

## SYSTEM CLOCK

timedatectl set-ntp true

## MIRRORS

echo "Generating mirrorlist"
reflector --latest 5 --protocol https --age 12 --sort rate --download-timeout 12 --save /etc/pacman.d/mirrorlist

## MOUNTS

mountpoint -q /mnt || {
  echo "Error: /mnt is not mounted"
  exit 1
}
mountpoint -q /mnt/boot || echo "Warning: /mnt/boot is not mounted (ESP?)"

## PACSTRAP

echo "Running pacstrap"
pacstrap -K /mnt base linux linux-firmware intel-ucode amd-ucode networkmanager wpa_supplicant sudo zsh git

## USER CREATION

echo "Creating user: $BASE_USER"
arch-chroot /mnt useradd -m -G wheel -s /bin/zsh "$BASE_USER"

## FSTAB

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

## COPY SCRIPTS

echo "Copying repo into /mnt/home/$BASE_USER"
cp -R "$ROOT" "/mnt/home/$BASE_USER/arch-install"

echo "Base installation phase complete"
echo "Now run: arch-chroot /mnt, then ./install.sh root"
