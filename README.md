# base-alpine 

## Note
Please make sure you use a tagged version of base-alpine, such as:

```Dockerfile
FROM vizzbuzz/base-alpine:0.7
```

## Introduction

This is a simple but powerful base image, based on Alpine Linux with [S6](http://skarnet.org/software/s6/) as a process supervisor and dnsmasq for DNS management, both of which have extremely small footprints adding virtually no runtime overhead and a minimal filesystem overhead.

Why a supervisor process? Firstly because it solves the [PID 1 Zombie Problem](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/) but most importantly because many containers need to run multiple processes.

Running multiple 'applications' in a single container is of course not The Docker Way (tm) - however running multiple *processes* is often required. [S6](http://skarnet.org/software/s6/) provides a very simple, low resource and elegant processor supervisor which fits in well with the Alpine Linux minimalism.

Also this image supports syslog logging, all syslog messages will be sent to stderr - no more losing syslog logging!

This image aims to be a suitable base image for people who want to deploy to [Tutum](http://tutum.co) - hence why it has a specific dnsmasq service for tutum.io.

[![](https://badge.imagelayers.io/vizzbuzz/base-alpine.svg)](https://imagelayers.io/?images=vizzbuzz/base-alpine:latest 'Get your own badge on imagelayers.io')

##Credits

Originally taken from https://github.com/just-containers/base-alpine credit to John Regan <john@jrjrtech.com>

