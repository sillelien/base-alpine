parseServiceLinks() {
    while read ip service_link host
    do
        curl -s -H "Authorization: $TUTUM_AUTH" -H "Accept: application/json" ${TUTUM_REST_HOST}${service_link} > /tmp/cur_service
        fqdn=$(cat /tmp/cur_service | jq -r '.public_dns')
        host=$(cat /tmp/cur_service  | jq -r '.name')
        echo "${ip} ${host} ${fqdn}" >> /tmp/hosts
    done
}


if [ -n "${TUTUM_AUTH}" ] && [ -n "${TUTUM_API_CALLS_FOR_DNS}" ]
then
    curl -s -H "Authorization: $TUTUM_AUTH" -H "Accept: application/json" ${TUTUM_REST_HOST}/api/v1/container/ > /tmp/containers.raw
    cat /tmp/containers.raw | jq -r '.objects  | map ( "\(.private_ip) \(.name) \(.public_dns)" ) | .[]' | tr -d '"' >> /tmp/hosts
    cat /tmp/containers.raw | jq -r '.objects  | map ( "\(.private_ip) \(.service) \(.name)" ) | .[]' | tr -d '"' | parseServiceLinks
fi