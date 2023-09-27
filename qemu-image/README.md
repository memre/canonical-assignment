# Canonical Assignment for Embedded Linux Containers Software Engineer

This is a simple assignment asked by Canonical for the Embedded Linux
Containers Software Engineer.

The simplest way to create a basic rootfs is to use `busybox`. I used
the latest stable version of it, and also added as submodule under
`ext/busybox` folder.

The configurations of the `busybox` are located under `assets` folder.
The static busybox binary will be added to `assets` folder anyway, but
the build script will also be located.

## Prerequisites

Tested on `Ubuntu 22.04.3 LTS x86_64`, kernel version `6.2.0-33-generic`.

Use ubuntu kernel directly from the ubuntu repositories.
TODO

## Build busybox for `initramfs`

TODO

## Initramfs creation

Actually might not required for this assignment, but still better to have one.

TODO steps

## Rootfs initialization

TODO:
Build busybox for the rootfs (possibly similar to initramfs version).
Create simple `/sbin/init` for the `"Hello world"`.
