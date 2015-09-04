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

function parseServiceLinks {
    while read ip service_link
    do
        curl -H "Authorization: $TUTUM_AUTH" -H "Accept: application/json" ${TUTUM_REST_HOST}${service_link}
        echo
        echo
    done
}

if env | grep "TUTUM_CONTAINER_FQDN"
then
    echo "We're running on Tutum"

    if [ -n "${TUTUM_AUTH}" ]
    then
#        curl -H "Authorization: $TUTUM_AUTH" -H "Accept: application/json" ${TUTUM_REST_HOST}/api/v1/service/ | jq -r '.objects | map ( "\(.name) \(.public_dns)" ) | .[]' | tr -d '\n' | tr -d '"' > /tmp services
#        while read service fqdn< /tmp/services
#        do
#            ip=$( nslookup $fqdn | grep Address | tail -1 | cut -d: -f2  | cut -d' ' -f2 2>/dev/null)
#            echo "${ip} ${host}" >> /tmp/hosts
#            echo "Added additional host ${host}.${suffix}=${ip}"
#            break
#        done
        curl -H "Authorization: $TUTUM_AUTH" -H "Accept: application/json" ${TUTUM_REST_HOST}/api/v1/container/ > /tmp/containers.raw
        cat /tmp/containers.raw | jq -r '.objects  | map ( "\(.private_ip) \(.name) \(.public_dns)" ) | .[]' | tr -d '"' > /tmp/containers
        cat /tmp/containers.raw | jq -r '.objects  | map ( "\(.private_ip) \(.service)" ) | .[]' | tr -d '"' | parseServiceLinks
#        curl -H "Authorization: $TUTUM_AUTH" -H "Accept: application/json" ${TUTUM_REST_HOST}/api/v1/service/ > /tmp/services.raw
        cat /tmp/containers >> /tmp/hosts

    fi

    env_vars=$(env | grep "_ENV_TUTUM_IP_ADDRESS=" | cut -d= -f1 | tr '\n' ' ' )
    echo "#Auto Generated - DO NOT CHANGE" >> /tmp/hosts
    for env_var in $env_vars
    do
      host=$(echo $env_var | awk -F"_ENV_TUTUM_IP_ADDRESS" '{print $1;}' | tr '_' '-' | tr '[:upper:]' '[:lower:]' )
      ip=$(eval "echo \$$env_var" | cut -d/ -f1)
      echo "${ip} ${host}" >> /tmp/hosts
      while ! ping -c 1 -q ${ip} &> /dev/null
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
      while ! ping -c 1 -q ${ip} &> /dev/null
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

