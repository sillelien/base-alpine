#!/usr/bin/with-contenv sh
echo "DNS hacks, first run."

if ! ( cat /etc/resolv.conf | grep "nameserver 127.0.0.1" )
then
    cp -f /etc/resolv.conf /etc/dnsmasq-resolv.conf
    echo "nameserver 127.0.0.1" > /etc/resolv.conf
fi

echo "Contents of dnsmasq-resolv.conf"
echo "-------------------"
cat /etc/dnsmasq-resolv.conf
echo
echo
. /bin/dns_hack.sh
cp -f /tmp/hosts /etc/hosts.links
