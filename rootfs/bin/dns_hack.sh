
env_vars=$(env | grep ".*_NAME=" | cut -d= -f1 | tr '\n' ' ' )
echo "#Auto Generated - DO NOT CHANGE" > /tmp/hosts
nameserver=$(cat /etc/resolv.conf | grep nameserver | head -1 | cut -d' ' -f2)
for env_var in $env_vars
do
  link=$(echo ${env_var%_NAME}  | tr '_' '-' | tr '[:upper:]' '[:lower:]')
  domain=$(cat /etc/resolv.conf | grep search | cut -d' ' -f2)
  if ping -c 1 "${link}.${domain}" &> /dev/null
  then
      ip=$(ping -c 1 "${link}.${domain}"| head -1 | cut -d'(' -f2 |  cut -d')' -f1)
  elif nslookup "${link}.${domain}" ${nameserver}  &> /dev/null
  then
      ip=$( nslookup "${link}.${domain}" ${nameserver}  | grep Address | tail -1 | cut -d: -f2  | cut -d' ' -f2 2>/dev/null)
  else
      ip=
  fi
  if [ -n "$ip" ]
  then
    echo "${ip} ${link}" >> /tmp/hosts
  else
    echo "ip ${link}.${domain} skipped, it didn't resolve." 1>&2
  fi

done

