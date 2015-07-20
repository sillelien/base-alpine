
env_vars=$(env | grep ".*_NAME=" | cut -d= -f1 | tr '\n' ' ' )
echo "#Auto Generated - DO NOT CHANGE" > /tmp/hosts
for env_var in $env_vars
do
  link=$(echo ${env_var%_NAME}  | tr '_' '-' | tr '[:upper:]' '[:lower:]')
  domain=$(cat /etc/dnsmasq-resolv.conf | grep search | cut -d' ' -f2)
  nameserver=$(cat /etc/dnsmasq-resolv.conf | grep nameserver | head -1 | cut -d' ' -f2)
  if nslookup "${link}.${domain}" ${nameserver}
  then
      ip=$( nslookup "${link}.${domain}" ${nameserver}  | grep Address | tail -1 | cut -d: -f2  | cut -d' ' -f2 2>/dev/null)
      if [ -n "$ip" ]
      then
        echo "${ip} ${link}" >> /tmp/hosts
      else
        echo "ip ${link}.${domain} skipped, it didn't resolve second time." 1>&2
      fi
  else
       echo "ip ${link}.${domain} skipped, it didn't resolve." 1>&2
  fi

done