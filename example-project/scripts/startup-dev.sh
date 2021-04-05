#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Setup loop devices
chmod ug+x $DIR/loop-setup.sh
$DIR/loop-setup.sh $INPUT_DIR

# Add SSH key (if no-password authentication is required)
key_name=ssh-key
mkdir ~/.ssh/
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
cat /shared/ssh-keys/$key_name.pub >> ~/.ssh/authorized_keys

set +e

# Copy dotfiles
cp -r /shared/dotfiles/{*,.[^.]*} /root/

# Copy apt config
cp -r /shared/apt-config/* /etc/apt/
