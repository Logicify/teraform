#!/usr/bin/env bash

#    Allows to safely mount EBS device to AWS instance and create file system if volume is not formatted yet.
#    Copyright (C) 2017 Dmitry Berezovsky
#
#    The MIT License (MIT)
#    Permission is hereby granted, free of charge, to any person obtaining
#    a copy of this software and associated documentation files
#    (the "Software"), to deal in the Software without restriction,
#    including without limitation the rights to use, copy, modify, merge,
#    publish, distribute, sublicense, and/or sell copies of the Software,
#    and to permit persons to whom the Software is furnished to do so,
#    subject to the following conditions:
#
#    The above copyright notice and this permission notice shall be
#    included in all copies or substantial portions of the Software.
#
#    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


FS="ext4"

if [ $# -ge 2 ]
then
    DEVICE=`readlink -f $1`
    MOUNT_POINT=$2
    PERMISSIONS=${3:-0664}
else
    echo "This utility allows mount block device and create file system if device is not formatted yet."
    echo "This tool will:
    1) mount device to the given location
    2) if device doesn't have file system it will create it using mkfs (ext4 will be used by default)
    3) create fstab record to mount the volume on system start
    4) chmod mount point to 0664"
    echo ""
    echo "Usage: mount-ebs <device> <mount-point>"
    echo "       mount-ebs /dev/sdh /srv"
    exit 1
fi

# Check if device exist
DEVICE_LINE=`lsblk $DEVICE | grep disk`
if [ -z "$DEVICE_LINE" ]; then
    echo "Device $DEVICE doesn't exist"
    exit 2
fi

#Check if it is already mounted
ACTUAL_MOUNT_POINT=`echo "$DEVICE_LINE" | awk '{ print substr(\$7,0) }'`
if [ -z "$ACTUAL_MOUNT_POINT" ]; then
    echo "Device is not mounted yet..."
else
    echo "Device is already mounted"
    exit 0
fi

# Check if device has file system
FS_INFO=`file -s $DEVICE | grep $FS`
if [ -z "$FS_INFO" ]; then
    echo "Device $DEVICE doesn't have file system. Creating..."
    mkfs -t $FS $DEVICE
fi

# Make sure mount point exists
mkdir -p $MOUNT_POINT

# Check if fstab record exists
FSTAB_RECORD=`cat /etc/fstab | grep $MOUNT_POINT`
if [ -z "$FSTAB_RECORD" ]; then
    echo "Creating FS TAB record..."
    FSTAB_RECORD="$DEVICE   $MOUNT_POINT    $FS rw,user,exec    0 0"
    echo "> $FSTAB_RECORD"
    echo "$FSTAB_RECORD" >> /etc/fstab
    echo "FS TAB written"
fi

echo "Mounting $DEVICE to $MOUNT_POINT"
mount $MOUNT_POINT

if [ -n "$PERMISSIONS" ]; then
    echo "Applying permissions $PERMISSIONS to the mounted partition"
    chmod $PERMISSIONS $MOUNT_POINT
fi