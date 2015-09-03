#!/usr/bin/env ash
nameserver=$(cat /etc/dnsmasq-resolv.conf | grep nameserver | head -1 | cut -d' ' -f2)
if [ -n "$BA_ADDITIONAL_HOSTS" ]
then
    service1=$(echo $TUTUM_SERVICE_FQDN | cut -d'.' -f2-)
    service2=$(echo $TUTUM_SERVICE_FQDN | cut -d'.' -f3-)
    cont1=$(echo $TUTUM_CONTAINER_FQDN | cut -d'.' -f2-)
    cont2=$(echo $TUTUM_CONTAINER_FQDN | cut -d'.' -f3-)
    for host in $BA_ADDITIONAL_HOSTS
    do
          for suffix in $service1 $service2 $cont1 $cont2
          do
              if ping -c 1 -q ${host}.${suffix}
              then
                ip=$( nslookup "${host}.${suffix}" ${nameserver}  | grep Address | tail -1 | cut -d: -f2  | cut -d' ' -f2 2>/dev/null)
                echo "${ip} ${host}.${suffix}" >> /tmp/hosts
              fi
          done
    done
fi
