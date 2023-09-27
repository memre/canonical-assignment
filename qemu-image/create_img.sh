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

CLEAN_ENV=false
KERNEL_VERSION=$(uname -r)
WORK_FOLDER=$(realpath -m "./work")
DOWNLOADS_FOLDER=$(realpath -m "${WORK_FOLDER}/downloads")
STAMPS_FOLDER=$(realpath -m "${WORK_FOLDER}/stamps")

INITRAMFS_FOLDER=$(realpath -m "${WORK_FOLDER}/initramfs")

TMP_FOLDER=$(realpath -m "${WORK_FOLDER}/tmp")
ROOTFS_FOLDER=$(realpath -m "${WORK_FOLDER}/rootfs")

ROOTFS_IMG="${WORK_FOLDER}/hdd.img"
INITRAMFS_IMG="${WORK_FOLDER}/initrd.img"
ROOTFS_SIZE="200M"

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

mark_done() {
  touch "${STAMPS_FOLDER}/$1"
}

check_stamp() {
  [ -e "${STAMPS_FOLDER}/$1" ] || return 1
  return 0
}

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

create_initramfs() {
  local stamp_file="create-initramfs"

  check_stamp $stamp_file || (
    mkdir -p $INITRAMFS_FOLDER{{,/usr}/bin,{,/usr}/sbin}

    local busybox_path=$(find "$TMP_FOLDER" -name 'busybox' | head -n 1)
    install -m 755 $busybox_path $INITRAMFS_FOLDER/bin

    touch $INITRAMFS_FOLDER/init
    chmod 755 $INITRAMFS_FOLDER/init

    cat << '__EOF' > $INITRAMFS_FOLDER/init
#!/bin/sh

echo "Starting initramfs based on Ubuntu 22.04"

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export ROOT_DEVICE=/dev/sda1
export INIT=/sbin/init
export rootmnt=/root

[ -d $rootmnt ] || mkdir -m 0700 $rootmnt

[ -d /dev ] || mkdir -m 0755 /dev
[ -d /sys ] || mkdir /sys
[ -d /proc ] || mkdir /proc
[ -d /tmp ] || mkdir /tmp
[ -d /run ] || mkdir /run

mount -t sysfs -o nodev,noexec,nosuid sysfs /sys
mount -t proc -o nodev,noexec,nosuid proc /proc

mount -t devtmpfs -o nosuid,mode=0755 udev /dev
mkdir /dev/pts
mount -t devpts -o noexec,nosuid,gid=5,mode=0620 devpts /dev/pts || true

mount -t tmpfs -o "nodev,noexec,nosuid,size=${RUNSIZE:-10%},mode=0755" tmpfs /run

mount $ROOT_DEVICE $rootmnt

mount -n -o move /run $rootmnt/run
mount -n -o move /sys $rootmnt/sys
mount -n -o move /proc $rootmnt/proc
mount -n -o move /dev $rootmnt/dev

exec /sbin/switch_root -c /dev/console $rootmnt $INIT $LEVEL
__EOF

    sudo chroot $INITRAMFS_FOLDER /bin/busybox --install -s

    pushd $INITRAMFS_FOLDER
    find . -print0 | cpio --null --create --verbose --format=newc | gzip --best > $INITRAMFS_IMG
    popd
    mark_done $stamp_file
  ) || die "Creating initramfs"
}

create_rootfs() {
  local stamp_file="create-rootfs"

  check_stamp $stamp_file || (
    local loop_device=$(sudo losetup -f)
    local busybox_path=$(find "$TMP_FOLDER" -name 'busybox' | head -n 1)
    local grub_cfg_file="$ROOTFS_FOLDER/boot/grub/grub.cfg"

    # Create a raw image
    dd if=/dev/zero of="$ROOTFS_IMG" bs=1 count=0 seek="$ROOTFS_SIZE"

    # Mount the partition to a loopback device
    sudo losetup "$loop_device" "$ROOTFS_IMG"

    # Use parted to create a partition
    sudo parted -s "$loop_device" mklabel msdos
    sudo parted -s "$loop_device" mkpart primary ext4 1MiB 100%

    sudo mkfs.ext4 "$loop_device"p1

    sudo mkdir -p $ROOTFS_FOLDER
    sudo mount "$loop_device"p1 "$ROOTFS_FOLDER"

    sudo mkdir -p $ROOTFS_FOLDER{{,/usr}/bin,{,/usr}/sbin,/boot/grub,/dev,/proc,/sys,/tmp,/run,/etc/init.d}

    sudo cp -rf $TMP_FOLDER/* $ROOTFS_FOLDER
    sudo cp -f $INITRAMFS_IMG $ROOTFS_FOLDER/boot

    sudo chroot $ROOTFS_FOLDER /bin/busybox --install -s

    cat << '__EOF' | sudo tee $ROOTFS_FOLDER/etc/inittab
::sysinit:/etc/init.d/rcS
__EOF

    cat << '__EOF' | sudo tee $ROOTFS_FOLDER/etc/init.d/rcS
#!/bin/sh

echo "Hello world"
__EOF

    sudo chmod +x $ROOTFS_FOLDER/etc/init.d/rcS

    # Install GRUB
    sudo grub-install --target=i386-pc --root-directory="$ROOTFS_FOLDER" "$loop_device"

    local kernel_image_path=$(find "$ROOTFS_FOLDER"/boot -name 'vmlinuz*' | head -n 1)
    local initrd_image_path=$(find "$ROOTFS_FOLDER"/boot -name 'initrd*' | head -n 1)
    # Generate GRUB configuration

    cat << __EOF | sudo tee $grub_cfg_file
set timeout=5
set default=0

menuentry "Hello World Linux" {
    linux /boot/$(basename $kernel_image_path) root=/dev/sda1 quiet
    initrd /boot/$(basename $initrd_image_path)
}
__EOF

    # Unmount the loopback device
    sudo umount "$ROOTFS_FOLDER"
    sudo losetup -d "$loop_device"
    mark_done $stamp_file
  ) || die "Creating rootfs"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kernel-version)
      shift
      KERNEL_VERSION=$1
      shift
      ;;
    --clean-env)
      CLEAN_ENV=true
      shift
      ;;
    *)
      usage
      ;;
  esac
done

# Clean up if requested
if [ "${CLEAN_ENV}" = true ]; then
  cleanup
fi

# Create necessary folders
create_folders

# Download packages
download_packages

# extract packages
extract_package "kernel" "linux-image-${KERNEL_VERSION}*.deb" "${TMP_FOLDER}"
extract_package "modules" "linux-modules-${KERNEL_VERSION}*.deb" "${TMP_FOLDER}"
extract_package "busybox" "busybox-static*.deb" "${TMP_FOLDER}"

# cleanup redundant files for this image
[ -d $TMP_FOLDER/usr ] && {
  echo "Removing redundant files"
  rm -rf $TMP_FOLDER/usr
}

# minimal initial ramdisk creation
create_initramfs

# minimal rootfs creation
create_rootfs

# run the image
qemu-system-x86_64 -m 256 -hda $ROOTFS_IMG
