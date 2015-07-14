FROM gliderlabs/alpine:3.2
MAINTAINER hello@neilellis.me

COPY rootfs /
COPY dns.sh /etc/services.d/dns/run
COPY syslog.sh /etc/services.d/syslog/run
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.13.0.0/s6-overlay-amd64.tar.gz /tmp/s6-overlay.tar.gz

# about nsswitch.conf - see https://registry.hub.docker.com/u/frolvlad/alpine-oraclejdk8/dockerfile/
RUN tar xvfz /tmp/s6-overlay.tar.gz -C / && apk -U add dnsmasq && chmod 755 /etc/services.d/dns/run /etc/services.d/syslog/run && mkdir /app && \
  echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
  addgroup -g 999 app && \
  adduser -D  -G app -s /bin/false -u 999 app

ENTRYPOINT ["/init"]
CMD [ "/bin/ash","-c","sleep $((2^32-1))" ]
