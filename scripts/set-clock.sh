# Change clock config
a=( $(grep -m 1 -B 2 "org.kde.plasma.digitalclock" $HOME/.config/plasma-org.kde.plasma.desktop-appletsrc | head -n 1 | awk -F '[][]' '{print $4, $8}') )

ops=("customDateFormat" "dateDisplayFormat" "dateFormat" "use24hFormat")
vals=("yy-MM-dd ddd t" "BesideTime" "custom" 2)

for i in {1..4}; do
	kwriteconfig6 \
		--file plasma-org.kde.plasma.desktop-appletsrc \
		--group Containments \
		--group ${a[1]} \
		--group Applets \
		--group ${a[2]} \
		--group Configuration \
		--group Appearance \
		--key "${ops[$i]}" \
		"${vals[$i]}"
done

