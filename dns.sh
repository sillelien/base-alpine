#!/bin/sh -x
exec dnsmasq --server=/tutum.io/8.8.8.8 --no-daemon
