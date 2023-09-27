# Canonical Assignment for Embedded Linux Containers Software Engineer

## Exercise 1

My dev environment is `Ubuntu 22.04 LTS`.

```bash
$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.3 LTS
Release:	22.04
Codename:	jammy
```

### Prerequisites

It was assumed that the commands I have been using are installed in the host
system already, I did not listed all of them since those are essential packages
anyway, like `e2fsprogs`, `grub2-common`, `apt`, `qemu-system-x86_64` etc.

### Initialization phase

The rootfs creator script uses 3 deb packages directly from the `Ubuntu`
repositories, whatever distro you use.

In this assignment, I preferred using `busybox` for both rootfs and initramfs
and decided to use `busybox-static` package since it doesn't require any
dependencies and it was very common to use `busybox` in Embedded Linux Systems,
it is so small, concise, has lots of commands that comes from `coreutils`,
`util-linux`, and many more.

I tried to make the script does its job without asking any password from `sudo`,
however, it requires extra work for me so that I moved on creating images
the usual way.

This script creates a `work` folder with the same folder with the script. Script
also creates sub folders for image creation:

- `work/downloads`: the folder to download prebuilt apt packages
- `work/stamps`: the folder to put stamp files to skip the tasks that already done
- `work/tmp`: to extract packages
- `work/initramfs`: the initramfs folder
- `work/rootfs`: the rootfs folder that the block device mounted.

The `initramfs` and `rootfs` folders were created when script gets to that specific
step.

Script might ask user password since it uses `sudo` for some packages since they
require root priviledges to mount raw image, create and mount partitions, copy
files to rootfs, etc.

Because of I was trying steps several times, I decided to put some stamps to a folder
indicates that the step was already done. This was an approach I was familiar with
in my previous works. If a step was already done, skip it. Additionally, you can
pass a parameter to create a clean environment:

```bash
$ ./create_img.sh -h
This script creates a simple rootfs by using Ubuntu repositories
Author: Mehmet Emre Atasever
Usage: ./create_img.sh [options]
Options:
  --clean-env                Clean up all before creating qemu image (optional)
  --kernel-version <version> Specify the kernel version to download (optional)
```

Additionally, you can specify the kernel version that was already in the Ubuntu
repositories. Default is `uname -r`.

### Image creation steps

#### Helper functions

To check for the stamps there are 2 simple functions. Those functions simply checks
for the stamp file:

```bash
mark_done() {
  touch "${STAMPS_FOLDER}/$1"
}

check_stamp() {
  [ -e "${STAMPS_FOLDER}/$1" ] || return 1
  return 0
}
```

To download the packages, I used directly `apt`, and used whatever Ubuntu repositories have:

```bash
download_packages() {
  local stamp_file="download-packages"

  check_stamp $stamp_file || (
    echo "Downloading required packages..."
    pushd "$DOWNLOADS_FOLDER" > /dev/null
    apt-get download \
      linux-image-$KERNEL_VERSION \
      linux-modules-$KERNEL_VERSION \
      busybox-static
    [ $? -eq 0 ] || return 1
    popd > /dev/null
  ) || die "downloading packages"
  mark_done $stamp_file
}

extract_package() {
  local name=$1
  local package_name=$2
  local package_work_folder=$3

  local stamp_file="extract-${1}"

  check_stamp $stamp_file || (
    echo "Extracting ${name}"

    deb_package=$(find $DOWNLOADS_FOLDER -name $package_name)
    dpkg -x "$deb_package" "$package_work_folder/"
    [ $? -eq 0 ] || return 1

    # Mark extraction as done
    mark_done $stamp_file
  ) || die "Extracting $1"
}
```

The usage of those functions are simple:

```bash
# Download packages
download_packages

# extract packages
extract_package "kernel" "linux-image-${KERNEL_VERSION}*.deb" "${TMP_FOLDER}"
extract_package "modules" "linux-modules-${KERNEL_VERSION}*.deb" "${TMP_FOLDER}"
extract_package "busybox" "busybox-static*.deb" "${TMP_FOLDER}"
```

Other simple functions are trivial, `die`, `create_folders`, etc.

```bash
usage() {
  echo "This script creates a simple rootfs by using Ubuntu repositories"
  echo "Author: Mehmet Emre Atasever"
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  --clean-env                Clean up all before creating qemu image (optional)"
  echo "  --kernel-version <version> Specify the kernel version to download (optional)"

  exit 1
}

die() {
  echo "Error! $1" >&2
  exit 1
}

cleanup() {
  if [ -d "${WORK_FOLDER}" ]; then
    mv "${WORK_FOLDER}"{,_$(date +%Y.%m.%d_%H.%M.%S)}
  fi
}

create_folders() {
  mkdir -p "${WORK_FOLDER}"
  mkdir -p "${DOWNLOADS_FOLDER}"
  mkdir -p "${TMP_FOLDER}"
  mkdir -p "${STAMPS_FOLDER}"
}
```

#### Create `initramfs`

Created very minimal `initramfs` that mounts rootfs and simply switches to rootfs.
Since there were only 1 partition, the `ROOT_DEVICE` was set statically.

For the required command sets, `busybox-static` ubuntu package was already enough,
so that I did not have to build my own.

#### Create raw image

TODO

#### Create partitions

I have only 1 partition for rootfs.

#### Format partition

TODO

#### Copy required files

- Copy `kernel` and `modules` _(`modules` might not be required in this assignment)_
- Copy `busybox` and install applets _(create symlinks to `busybox`)_

#### bootloader

- Install bootloader _(`grub` in my implementation)_
