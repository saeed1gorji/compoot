#!/usr/bin/env bash

# Author: Saeed Gorji <saeed1gorji[at]gmail[dot]com>
#
# This script enables use of loop devices inside the container and/or fixes
# probable relevent issues to make sure image mounting works without problems.
# It is intended to be run inside the container at startup.
# First argumenst can be optionally provided as directory path. Otherwise
# default path is taken into account. 
# For each iso image file, a loop device will be assigned by creating the node.
# The container should be spawned in privileged mode and volume /dev:/dev 
# mapped.
#
# Inspired from @onyfahrion script:
# https://github.com/moby/moby/issues/27886#issuecomment-417074845

set -e

DEFAULT_DIR="/shared/input"
ARG_DIR=${1%/}

INPUT_DIR=$([ -z $ARG_DIR ] && echo $DEFAULT_DIR || echo $ARG_DIR)
INPUT_DIR=$(realpath $INPUT_DIR)

IMAGES=$(ls $INPUT_DIR -a | sort | grep -E ".iso$")

for ISO_NAME in $IMAGES; do
    ISO_PATH=${INPUT_DIR}/${ISO_NAME}
    LOOPDEV=$(losetup --raw --noheadings --output "NAME" -j $ISO_PATH)
    if [ -z $LOOPDEV ]; then
        LOOPDEV=$(losetup --find --show ${ISO_PATH})
    fi

    NUMS=$(lsblk --raw --noheadings --output "MAJ:MIN" $LOOPDEV)
    MAJ=$(echo $NUMS | cut -d: -f1)
    MIN=$(echo $NUMS | cut -d: -f2)
    # Create device node if missing
    if [ ! -e $LOOPDEV ]; then
        echo "  Creating node ${LOOPDEV}..."
        mknod $LOOPDEV b $MAJ $MIN;
    fi
    echo "Loop assigned: $LOOPDEV <-- $ISO_NAME"
done
echo "ALL DONE."
