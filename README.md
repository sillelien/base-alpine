
# base-alpine 

Base-alpine provides an image suitable for running Alpine Linux in Tutum/Kubernetes style hosted distributed environments. It comes with S6 process manager by default, if you don't use a process manager things can get a bit messy.

[![](https://badge.imagelayers.io/vizzbuzz/base-alpine.svg)](https://imagelayers.io/?images=vizzbuzz/base-alpine:latest 'Get your own badge on imagelayers.io')

-------

**If you use this project please consider giving us a star on [GitHub](http://github.com/sillelien/base-alpine). Also if you can spare 30 secs of your time please let us know your priorities here https://sillelien.wufoo.com/forms/zv51vc704q9ary/  - thanks, that really helps!**

Please contact us through chat or through GitHub Issues.

[![GitHub Issues](https://img.shields.io/github/issues/sillelien/base-alpine.svg)](https://github.com/sillelien/base-alpine/issues)

[![Join the chat at https://gitter.im/sillelien/base-alpine](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/sillelien/base-alpine?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

-------

## Note
Please make sure you use a tagged version of base-alpine, such as:

```Dockerfile
FROM sillelien/base-alpine:0.10
```

[![Deploy to Tutum](https://s.tutum.co/deploy-to-tutum.svg)](https://dashboard.tutum.co/stack/deploy/)
## Introduction

This is a simple but powerful base image, based on Alpine Linux with [S6](http://skarnet.org/software/s6/) as a process supervisor and dnsmasq for DNS management, both of which have extremely small footprints adding virtually no runtime overhead and a minimal filesystem overhead.

Why a supervisor process? Firstly because it solves the [PID 1 Zombie Problem](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/) but most importantly because many containers need to run multiple processes.

Running multiple 'applications' in a single container is of course not The Docker Way (tm) - however running multiple *processes* is often required. [S6](http://skarnet.org/software/s6/) provides a very simple, low resource and elegant processor supervisor which fits in well with the Alpine Linux minimalism.

Also this image supports syslog logging, all syslog messages will be sent to stderr - no more losing syslog logging!


## Read this first (Gotchas)

* Use Fully Qualified Domain Names (FQDN) always, Alpine Linux does not support the 'search' value in resolv.conf. So you must use myserver.local instead of just myserver.

## Usage Notes

### Shell

Alpine Linux uses [BusyBox](http://www.busybox.net/) to provide a lot of the core Unix/Linux utilities. As part of that we get the [Ash](http://linux.die.net/man/1/ash) shell, which is very similar to the Bourne (BASH) shell. Just make sure you realise there are differences, it is almost POSIX compliant, so if in doubt use the POSIX complaint syntax rather than BASH extensions.
 
You can of course install bash - and why not?. Doing so will add a few more meg to your *tiny* image.



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

The authors of musl-libc decided for their [own reasons](http://wiki.musl-libc.org/wiki/Functional_differences_from_glibc#Name_Resolver_.2F_DNS) not to support the `search` or `domain` options in resolv.conf. This means that systems that rely on that behaviour (include Tutum.co and Kubernetes) cannot use Alpine Linux properly. This base image does some [magic](https://github.com/vizzbuzz/base-alpine/blob/master/rootfs/etc/services.d/dns-hack/run) for you to make sure that all linked containers resolve to their shortnames correctly. This magic works hand in hand with `dnsmasq` which is a tiny (uses about 17K of memory) DNS cache and forwarder. 

You can add additional flags using the environment variable DNSMASQ_ARGS

### Understanding the DNS Startup/Boot Sequence

The entire boot sequence related to DNS and related fixes is timelimited by the env var `DNS_INIT_TIMEOUT` which defaults to 45 seconds. If the timeout is exceeded the entire container is shutdown.

#### Makes sure Dnsmasq is the current nameserver

If it isn't it copies the current `/etc/resolv.conf` into `/etc/dnsmasq-resolv.conf`.

#### Checks whether the container is on Tutum

If the container is running on Tutum all linked containers will be added to the hosts file, not just ones with exposed ports.

#### Adds linked containers to /etc/hosts

If on Tutum this is all containers, otherwise only those who expose ports.

#### Pings each host

The script will pause while it pings each linked container. The script won't finish (and therefore the container won't start) until all can be reached.

#### Starts Dnsmasq

Dnsmasq is the local caching nameserver that is used to resolve all DNS queries from within the container.

#### Starts monitoring loop 

The monitoring loop checks for changes to `/etc/resolv.conf` and when found updates the DNS information.

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

Originally taken from https://github.com/just-containers/base-alpine credit to John Regan <john@jrjrtech.com> which itself is taken from https://github.com/gliderlabs/docker-alpine credit to [Gliderlabs](http://gliderlabs.com/) for that.

--------

[![GitHub License](https://img.shields.io/github/license/sillelien/base-alpine.svg)](https://raw.githubusercontent.com/sillelien/base-alpine/master/LICENSE)

#Referral Links

This is an open source project, which means that we are giving our time to you for free. However like yourselves, we do have bills to pay. Please consider visiting some of these excellent services, they are not junk we can assure you, all services we would or do use ourselves.

[Really Excellent Dedicated Servers from Limestone Networks](http://www.limestonenetworks.com/?utm_campaign=rwreferrer&utm_medium=affiliate&utm_source=RFR16798) - fantastic service, great price.

[Low Cost and High Quality Cloud Hosting from Digital Ocean](https://www.digitalocean.com/?refcode=7b4639fc8194) - truly awesome service.

[Excellent Single Page Website Creation and Hosting from Strikingly](http://strk.ly/?uc=kDaE2vgzc3F) - http://sillelien.com uses this.

#Copyright and License

(c) 2015 Sillelien all rights reserved. Please see [LICENSE](https://raw.githubusercontent.com/sillelien/base-alpine/master/LICENSE) for license details of this project. Please visit http://sillelien.com for help and commercial support or raise issues on [GitHub](https://github.com/sillelien/base-alpine/issues).

<div width="100%" align="right">
<img src='https://da8lb468m8h1w.cloudfront.net/v2/cpanel/8398500-121258714_5-s1-v1.png?palette=1' >
</div>
