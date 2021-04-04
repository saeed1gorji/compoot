#!/usr/bin/env bash

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Add connect script
cp /shared/scripts/connect-vpn /usr/bin/connect-vpn
chmod ug+x /usr/bin/connect-vpn

# Add SSH key
key_name=ssh-key
mkdir -p ~/.ssh/
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
cat /shared/ssh-keys/$key_name.pub >> ~/.ssh/authorized_keys
