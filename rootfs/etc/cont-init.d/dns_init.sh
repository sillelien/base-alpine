#!/usr/bin/with-contenv ash

export INIT_SCRIPT_PID=$$

( sleep 30 ; [ -f /var/run/dns.init ] || ( echo "Timed out setting up DNS." && s6-nuke && kill -2 1 ) ) &

echo "DNS hacks, initial hosts generation."
cp /etc/hosts /etc/hosts.orig
cp /etc/hosts /tmp/hosts
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

if env | grep "_ENV_TUTUM_IP_ADDRESS"
then
    echo "We're running on Tutum"
    env_vars=$(env | grep "_ENV_TUTUM_IP_ADDRESS=" | cut -d= -f1 | tr '\n' ' ' )
    echo "#Auto Generated - DO NOT CHANGE" >> /tmp/hosts
    for env_var in $env_vars
    do
      host=$(echo $env_var | awk -F"_ENV_TUTUM_IP_ADDRESS" '{print $1;}' | tr '_' '-' | tr '[:upper:]' '[:lower:]' )
      ip=$(eval "echo \$$env_var" | cut -d/ -f1)
      echo "${ip} ${host}" >> /tmp/hosts
      while ! ping -c 1 -q ${ip} 
      do
        echo "Waiting for IP address ${ip} to be reachable"
        sleep 1
      done
    done
else
    echo "We're not running on Tutum"
    env_vars=$(env | grep ".*_PORT_.*_TCP_ADDR=" | cut -d= -f1 | tr '\n' ' ' )
    echo "#Auto Generated - DO NOT CHANGE" >> /tmp/hosts
    for env_var in $env_vars
    do
      host=$(echo $env_var | awk -F"_PORT_" '{print $1;}' | tr '_' '-' | tr '[:upper:]' '[:lower:]' )
      ip=$(eval "echo \$$env_var")
      echo "${ip} ${host}" >> /tmp/hosts
      while ! ping -c 1 -q ${ip}
      do
        echo "Waiting for IP address ${ip} to be reachable"
        sleep 1
      done
    done
fi

sort -u < /tmp/hosts > /etc/hosts

echo "Initial DNS calculated"
echo "-------------------"
cat /etc/hosts
echo
echo

touch /var/run/dns.init

