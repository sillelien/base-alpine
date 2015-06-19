FROM gliderlabs/alpine:3.2
MAINTAINER hello@neilellis.me

COPY rootfs /
RUN apk -U add dnsmasq
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.12.0.0/s6-overlay-amd64.tar.gz /tmp/s6-overlay.tar.gz
RUN tar xvfz /tmp/s6-overlay.tar.gz -C /
COPY dns.sh /etc/services.d/dns/run
RUN chmod 755 /etc/services.d/dns/run

# about nsswitch.conf - see https://registry.hub.docker.com/u/frolvlad/alpine-oraclejdk8/dockerfile/
RUN echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

ENTRYPOINT ["/init"]
CMD []
