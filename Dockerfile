FROM gliderlabs/alpine:3.2
MAINTAINER hello@neilellis.me

COPY rootfs /
COPY dns.sh /etc/services.d/dns/run
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.13.0.0/s6-overlay-amd64.tar.gz /tmp/s6-overlay.tar.gz

# about nsswitch.conf - see https://registry.hub.docker.com/u/frolvlad/alpine-oraclejdk8/dockerfile/
RUN tar xvfz /tmp/s6-overlay.tar.gz -C / && apk -U add dnsmasq && chmod 755 /etc/services.d/dns/run && mkdir /app && \
echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

ENTRYPOINT ["/init"]
CMD []
