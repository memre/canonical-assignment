#!/bin/bash

# Canonical Assignment for Embedded Linux Containers Software Engineer
# Author:Mehmet Emre Atasever
# Email:m.emre.atasever ~ gmail.com

# This script simply creates a minimal initramfs and rootfs
# and prints "Hello World" after the boot up.

# Full requirements of the exercise are following:
#
# Bootable Linux image via QEMU
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# In this exercise you are expected to create a shell script that will run in
# a Linux environment (will be tested on Ubuntu 20.04 LTS or 22.04 LTS). This
# shell script should create and run an AMD64 Linux filesystem image using
# QEMU that will print “hello world” after successful startup. Bonus points for
# creating a fully bootable filesystem image (but not mandatory). The system
# shouldn’t contain any user/session management or prompt for login information
# to access the filesystem.
#
# You can use any version/flavor of the Linux kernel. The script can either
# download and build the kernel from source on the host environment or download
# a publicly available pre-built kernel.
#
# The script shouldn’t ask for any user input unless superuser privileges are
# necessary for some functionality, therefore any additional information that
# you require for the script should be available in your repository.
#
# The script should run within the working directory and not consume any other
# locations on the host file system.

clean_env=false
kernel_version=$(uname -r)
work_folder=$(realpath -m "./work")
downloads_folder=$(realpath -m "${work_folder}/downloads")

kernel_folder=$(realpath -m "${work_folder}/linux")
busybox_folder=$(realpath -m "${work_folder}/busybox")
stamps_folder=$(realpath -m "${work_folder}/stamps")

usage() {
  echo "This script creates a simple rootfs by using Ubuntu repositories"
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  --clean-env                Clean up all before creating qemu image"
  echo "  --kernel-version <version> Specify the kernel version to download (optional)"

  exit 1
}

die() {
  echo "Error! $1" >&2
  exit 1
}

cleanup() {
  if [ -d "${work_folder}" ]; then
    mv "${work_folder}"{,_$(date +%Y.%m.%d_%H.%M.%S)}
  fi
}

mark_done() {
  touch "${stamps_folder}/$1"
}

check_stamp() {
  [ -e "${stamps_folder}/$1" ] || return 1
  return 0
}

create_folders() {
  mkdir -p "${work_folder}"
  mkdir -p "${downloads_folder}"
  mkdir -p "${kernel_folder}"
  mkdir -p "${busybox_folder}"
  mkdir -p "${stamps_folder}"
}

download_packages() {
  echo "Downloading required packages..."
  stamp_file="download-packages"
  check_stamp $stamp_file || (
    set -e
    pushd "$downloads_folder" > /dev/null
    apt-get download \
      linux-image-$kernel_version \
      linux-modules-$kernel_version \
      busybox-initramfs
    [ $? -eq 0 ] || return 1
    popd > /dev/null
  ) || die "downloading packages"
  mark_done $stamp_file
}

extract_package() {
  name=$1
  package_name=$2
  package_work_folder=$3

  stamp_file="extract-${1}"
  check_stamp $stamp_file || (
    echo "Extracting ${name}"

    deb_package=$(find $downloads_folder -name $package_name)
    dpkg -x "$deb_package" "$package_work_folder/"
    [ $? -eq 0 ] || return 1

    # Mark extraction as done
    mark_done $stamp_file
  ) || die "Extracting $1"
}

INITRAMFS_FOLDER=$(realpath -m "${work_folder}/initramfs")
TMP_FOLDER=$(realpath -m "${work_folder}/tmp")
INITRAMFS_IMG="${work_folder}/initrd.img"

create_initramfs() {
  local stamp_file="create-initramfs"

  check_stamp $stamp_file || (
    mkdir -p $INITRAMFS_FOLDER{{,/usr}/bin,{,/usr}/sbin}

    local busybox_path="${work_folder}/assets/busybox"
    install -m 755 $busybox_path $INITRAMFS_FOLDER/bin

    touch $INITRAMFS_FOLDER/init
    chmod 755 $INITRAMFS_FOLDER/init

    cat << '__EOF' > $INITRAMFS_FOLDER/init
#!/bin/sh

echo "initramfs test"

mkdir /dev /sys /proc /tmp /run

mount -t sysfs -o nodev,noexec,nosuid sysfs /sys
mount -t proc -o nodev,noexec,nosuid proc /proc

mount -t devtmpfs -o nosuid,mode=0755 udev /dev
mkdir /dev/pts
mount -t devpts -o noexec,nosuid,gid=5,mode=0620 devpts /dev/pts || true
mount -t tmpfs -o "nodev,noexec,nosuid,size=${RUNSIZE:-10%},mode=0755" tmpfs /run

/bin/sh
__EOF

    sudo chroot $INITRAMFS_FOLDER /bin/busybox --install -s

    pushd $INITRAMFS_FOLDER
    find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > $INITRAMFS_IMG
    popd
    mark_done $stamp_file
  ) || die "Creating initramfs"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kernel-version)
      shift
      kernel_version=$1
      shift
      ;;
    --clean-env)
      clean_env=true
      shift
      ;;
    *)
      usage
      ;;
  esac
done

# Clean up if requested
if [ "${clean_env}" = true ]; then
  cleanup
fi

# Create necessary folders
create_folders

# Download packages
download_packages

# extract packages
extract_package "kernel" "linux-image-${kernel_version}*.deb" "${kernel_folder}"
extract_package "modules" "linux-modules-${kernel_version}*.deb" "${kernel_folder}"

create_initramfs

# qemu-system-x86_64 -hda bla.img \
#   -initrd initramfs.cpio.gz \
#   -kernel ../work_2023.09.26_20.15.42/linux/boot/vmlinuz-6.2.0-33-generic

qemu-system-x86_64 -initrd $INITRAMFS_IMG \
  -kernel ./work/linux/boot/vmlinuz-6.2.0-33-generic
