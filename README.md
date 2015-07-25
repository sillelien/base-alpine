# base-alpine 

## Note
Please make sure you use a tagged version of base-alpine, such as:

```Dockerfile
FROM vizzbuzz/base-alpine:0.9.1
```

## Introduction

This is a simple but powerful base image, based on Alpine Linux with [S6](http://skarnet.org/software/s6/) as a process supervisor and dnsmasq for DNS management, both of which have extremely small footprints adding virtually no runtime overhead and a minimal filesystem overhead.

Why a supervisor process? Firstly because it solves the [PID 1 Zombie Problem](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/) but most importantly because many containers need to run multiple processes.

Running multiple 'applications' in a single container is of course not The Docker Way (tm) - however running multiple *processes* is often required. [S6](http://skarnet.org/software/s6/) provides a very simple, low resource and elegant processor supervisor which fits in well with the Alpine Linux minimalism.

Also this image supports syslog logging, all syslog messages will be sent to stderr - no more losing syslog logging!

## Usage Notes

### Shell

Alpine Linux uses [BusyBox](http://www.busybox.net/) to provide a lot of the core Unix/Linux utilities. As part of that we get the [Ash](http://linux.die.net/man/1/ash) shell, which is very similar to the Bourne (BASH) shell. Just make sure you realise there are differences, it is almost POSIX compliant, so if in doubt use the POSIX complaint syntax rather than BASH extensions.
 
You can of course install bash - and why not?. Doing so will add a few more meg to your *tiny* image.

[![](https://badge.imagelayers.io/vizzbuzz/base-alpine.svg)](https://imagelayers.io/?images=vizzbuzz/base-alpine:latest 'Get your own badge on imagelayers.io')

### S6

[S6](http://skarnet.org/software/s6/) is a supervisor or process management system, similar to using runit or even supervisord in nature.It's a very powerful system so I recommend reading the [docs](http://skarnet.org/software/s6/) - however the quick and dirty way to get started is:

1) Just use CMD as usual in your Dockerfile, the ENTRYPOINT is set to a script that will run the CMD under S6 and shutdown the entire image on CMD failure.

2) Add additional scripts using this format

```Dockerfile
COPY myservice.sh /etc/services.d/myservice/run
RUN chmod 755 /etc/services.d/myservice/run
```

Note: If you want to get access to environment variables passed in to your container start your scripts with:

```shell
#!/usr/bin/with-contenv sh
```

### Syslog

The base image contains a running syslog daemon, which is set to send all output to `stderr` - this ensures you don't lose any messages sent by Linux applications.

### DNS and the Alpine resolv.conf problem.

The authors of musl-libc decided for their [own reasons](http://wiki.musl-libc.org/wiki/Functional_differences_from_glibc#Name_Resolver_.2F_DNS) not to support the `search` or `domain` options in resolv.conf. This means that systems that rely on that behaviour (include Tutum.co) cannot use Alpine Linux properly. This base image does some [magic](https://github.com/vizzbuzz/base-alpine/blob/master/rootfs/etc/services.d/dns-hack/run) for you to make sure that all linked containers resolve to their shortnames correctly. This magic works hand in hand with `dnsmasq` which is a tiny (uses about 17K of memory) DNS cache and forwarder. 

You can add additional flags using the environment variable DNSMASQ_ARGS

## Good Practises

### Don't Run as Root

During the build we run:

```Dockerfile
RUN addgroup -g 999 app && adduser -D  -G app -s /bin/false -u 999 app
```

This creates a non root user for you to use. Then in your S6 scripts you can run your commands using:

```BASH
#!/usr/bin/env sh
exec s6-applyuidgid -u 999 -g 999 mycommand.sh 
```

The `exec` will write over the shell's process space reducing the memory overhead and `s6-applyuidgid -u 999 -g 999` will run it as `app` the non root user.


### Keep it Small

Don't put `RUN` instructions in your `Dockerfile`, instead create a `build.sh` script and run that:

```Dockerfile
COPY build.sh /build.sh
RUN chmod 755 /build.sh
RUN /build.sh
```

Of course you can save doing this until it's a last minute optimization when you've got everything running. 

In your `build.sh` file start with:

```BASH
#!/usr/bin/env sh
set -ex
cd /tmp
apk upgrade
apk update
```

And end with

```BASH
apk del <applications that were used only for building, like gcc, make etc.>
rm -rf /tmp/*
rm -rf /var/cache/apk/*
```

This will clean up any mess you created while building. `set -e` causes the script to fail on any single commands failure and `set -x` lists all commands executed to `stderr`


### Consider logging using `logger` 

The [logger](http://man7.org/linux/man-pages/man1/logger.1.html) command is a command-line tool to send the output of another command to syslog simply by doing

```BASH
 mycommand 2>&1 | logger
```

I would advise using it where possible instead of just sending output directly to stderr - this means that if you decide to collect your log entries via syslog at a later time you won't need to change your app.


## Differences to Ubuntu

### APK not APT

Instead of `apt-get install -y` you have `apk add`

### Find packages 

You can search for packages by name or by file contents here: http://pkgs.alpinelinux.org/packages

### Curl needs to be added

`apk add curl ca-certificates`
 
### The standard build tools
 
 `apk add make gcc build-base`
 
### Python
 
 `apk add python python-dev py-pip`
 
 `curl https://bootstrap.pypa.io/ez_setup.py  | python`
 
### Java
 
 Use our `vizzbuzz/base-java` image which adds Java to this image.


##Credits

Originally taken from https://github.com/just-containers/base-alpine credit to John Regan <john@jrjrtech.com>

