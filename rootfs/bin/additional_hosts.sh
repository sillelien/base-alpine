
if [ -n "$BA_ADDITIONAL_HOSTS" ] && [ -n "$TUTUM_SERVICE_FQDN" ]
then
    nameserver=$(cat /etc/resolv.conf | grep nameserver | head -1 | cut -d' ' -f2)
    search=$(cat /etc/resolv.conf | grep search | head -1 | cut -d' ' -f2)
    service1=$(echo $TUTUM_SERVICE_FQDN | cut -d'.' -f2-)
    service2=$(echo $TUTUM_SERVICE_FQDN | cut -d'.' -f3-)
    cont1=$(echo $TUTUM_CONTAINER_FQDN | cut -d'.' -f2-)
    cont2=$(echo $TUTUM_CONTAINER_FQDN | cut -d'.' -f3-)

    for host in $BA_ADDITIONAL_HOSTS
    do
          for suffix in $search $service1 $service2 $cont1 $cont2
          do
              if ping -t 1 -c 1 ${host}.${suffix} &> /dev/null
              then
                ip=$( nslookup ${host}.${suffix} | grep Address | tail -1 | cut -d: -f2  | cut -d' ' -f2 2>/dev/null)
                echo "${ip} ${host}" >> /tmp/hosts
                echo "Added additional host ${host}.${suffix}=${ip}"
                break
              fi
          done
    done
fi


