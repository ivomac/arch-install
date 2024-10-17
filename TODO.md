
- Bucket:
	* Enable automatic backups:
		systemctl --user enable bucket.timer

- KDE:
	* Import window rules
	* Set user avatar
	* Set wallpaper (including lockscreen)
	* Disable "Show Desktop" widget
	* Disable permanent sessions
	* KDEconnect:
		- Pair with phone

- Qbittorrent:
	* Add to autostart

- RClone

- Syncthing:
	* Setup folders (like phone camera)

- Firefox:
	* Restore backups of sidebery settings and tab snapshots
	* Setup topbar icons
	* Gmail notifications:
		- Gmail > "General" > "Desktop Notifications" > "...enable desktop notif..."
	* Google Calendar notifications:
		- Google Calendar > "Settings" > "General" > "Notification settings"
	* Google Drive notifications
	* Search engines:
		- google ncr:
			https://www.google.com/search?q=%s&pws=0&gl=us&gws_rd=cr

		- google images:
			https://www.google.com/search?&pws=0&gl=us&q=%s&udm=2&bih=865&dpr=1.2

		- libgen.is:
			https://libgen.is/search.php?req=%s&open=0&res=100&view=detailed&phrase=0&column=def

		- 1337x.to:
			https://1337x.to/sort-search/%s/seeders/desc/1/

		- youtube.com:
			https://www.youtube.com/results?search_query=%s

		- thepiratebay.org:
			https://thepiratebay.org/search.php?q=%s&orderby=seeders

- AUR/Multilib packages to install:
	Games:
		steam
		protonup-qt
	ML:
		amdgpu_top
		python-huggingface-hub
		python-pyspark
		python-tensorstore
		python-torchfunc
		python-torchaudio(-rocm)
		python-torchvision(-rocm)
	Other:
		lazydocker-bin

