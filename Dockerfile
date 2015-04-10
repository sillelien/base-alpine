FROM gliderlabs/alpine:3.1
MAINTAINER John Regan <john@jrjrtech.com>

COPY rootfs /

ADD https://github.com/just-containers/s6-overlay-builder/releases/download/v1.9.1.0/s6-overlay-portable-amd64.tar.gz /tmp/s6-overlay.tar.gz
RUN tar xvfz /tmp/s6-overlay.tar.gz -C /

ENTRYPOINT ["/init"]
CMD []
