#!/usr/bin/with-contenv ash


if [ -z "$DNS_INIT_TIMEOUT" ]
then
    DNS_INIT_TIMEOUT=45
fi

( sleep $DNS_INIT_TIMEOUT ; [ -f /var/run/dns.init ] || ( echo "Timed out setting up DNS." && s6-nuke && kill -2 1 ) ) &

echo "DNS hacks, initial hosts generation."
cp /etc/hosts /etc/hosts.orig
cp /etc/hosts /tmp/hosts
if ! ( cat /etc/resolv.conf | grep "nameserver 127.0.0.1" )
then
    cp -f /etc/resolv.conf /etc/dnsmasq-resolv.conf
    echo "nameserver 127.0.0.1" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
fi

echo "Contents of dnsmasq-resolv.conf"
echo "-------------------"
cat /etc/dnsmasq-resolv.conf
echo
echo


if env | grep "TUTUM_CONTAINER_FQDN"
then
    echo "We're running on Tutum"

    . /bin/get_hosts_from_tutum.sh

    . /bin/tutum_dns_hack.sh
else
    echo "We're not running on Tutum"

    . /bin/non_tutum_dns_hack.sh
fi

sort -u < /tmp/hosts > /etc/hosts

echo "Initial DNS calculated"
echo "-------------------"
cat /etc/hosts
echo
echo

touch /var/run/dns.init

