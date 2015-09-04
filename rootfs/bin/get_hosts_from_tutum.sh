parseServiceLinks() {
    while read ip service_link
    do
        host=$(curl -H "Authorization: $TUTUM_AUTH" -H "Accept: application/json" ${TUTUM_REST_HOST}${service_link} | jq -r '.public_dns')
        echo "${ip} ${host}" >> /tmp/hosts
    done
}


if [ -n "${TUTUM_AUTH}" ]
then
    curl -H "Authorization: $TUTUM_AUTH" -H "Accept: application/json" ${TUTUM_REST_HOST}/api/v1/container/ > /tmp/containers.raw
    cat /tmp/containers.raw | jq -r '.objects  | map ( "\(.private_ip) \(.name) \(.public_dns)" ) | .[]' | tr -d '"' >> /tmp/hosts
    cat /tmp/containers.raw | jq -r '.objects  | map ( "\(.private_ip) \(.service)" ) | .[]' | tr -d '"' | parseServiceLinks

fi