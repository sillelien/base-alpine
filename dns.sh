#!/bin/sh -x
exec dnsmasq --server=/tutum.io/162.159.24.22 --server=/tutum.io/162.159.25.72 --no-daemon
