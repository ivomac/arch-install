## Arch Linux installation

Backup:
  * Media
  * Docs

### Preparation

```bash
iwctl station wlan0 connect (SSID)
curl -L https://github.com/ivomac/arch-install/archive/refs/heads/main.tar.gz | tar -xzv
cd arch-install-main
./install.sh nvme
```

### Partitioning (manual)

Partition layout varies per machine. Minimum: EFI system partition (>=512MiB) + root partition.

1. Create GPT partition table on the target drive
2. EFI system partition: type EFI System (ef00), >=512MiB
3. Root partition: type Linux root x86-64 (8304), remaining space
4. (Optional) Swap partition — zram-generator is installed later as an alternative

Example for NVMe:
```bash
fdisk /dev/nvme0n1
  g               # create GPT partition table
  n → 1 → Enter → +1G → t → 1   # EFI partition
  n → 2 → Enter → Enter         # root partition
  w                              # write and exit

mkfs.fat -F32 /dev/nvme0n1p1
mkfs.ext4 /dev/nvme0n1p2
mount /dev/nvme0n1p2 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

### Installation

```bash
./install.sh base (user)
arch-chroot /mnt
cd /home/(user)/arch-install
./install.sh root <hostname>
su (user)
./install.sh user <SSH_REPO_API_KEY>
reboot
nmcli device wifi connect (SSID) password (pass)
./install.sh graphical
```
