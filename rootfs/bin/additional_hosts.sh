
if [ -n "$BA_ADDITIONAL_HOSTS" ] && [ -n "$TUTUM_SERVICE_FQDN" ]
then
    service1=$(echo $TUTUM_SERVICE_FQDN | cut -d'.' -f2-)
    service2=$(echo $TUTUM_SERVICE_FQDN | cut -d'.' -f3-)
    cont1=$(echo $TUTUM_CONTAINER_FQDN | cut -d'.' -f2-)
    cont2=$(echo $TUTUM_CONTAINER_FQDN | cut -d'.' -f3-)
    for host in $BA_ADDITIONAL_HOSTS
    do
          for suffix in $service1 $service2 $cont1 $cont2
          do
              if ping -t 1 -c 1 "${host}.${suffix}" && nslookup "${host}.${suffix}" 127.0.0.1
              then
                ip=$( nslookup "${host}.${suffix}" 127.0.0.1 | grep Address | tail -1 | cut -d: -f2  | cut -d' ' -f2 2>/dev/null)
                echo "${ip} ${host}.${suffix}" >> /tmp/hosts
                echo "Added additional host ${host}.${suffix}=${ip}"
              fi
          done
    done
fi
