
## NO IPv6

echo "Disabling IPv6"

echo "
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
" > /etc/sysctl.d/40-no-ipv6.conf

