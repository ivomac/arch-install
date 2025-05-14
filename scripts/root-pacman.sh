## PACMAN

echo "Setting up pacman"

sed -i \
	-e 's/#Color/Color/' \
	-e 's/.*ParallelDownloads.*/ParallelDownloads = 10/' \
	/etc/pacman.conf

