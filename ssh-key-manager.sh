#!/usr/bin/env bash

set -e

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
last_dir=$(pwd)
mkdir -p $dir/ssh-keys
cd $dir/ssh-keys

action="$1"
key_name=ssh-key

generate_keys ()
{
    if [ -e "$key_name" ]; then
        # If the pair is available, keep them (do nothing)
        [ -e "$key_name.pub" ] && return

        ssh-add -d $key_name && rm -f $key_name &>/dev/null
    fi
    # Generate new keys
    ssh-keygen -t rsa -N "" -f $key_name
    chmod 600 $key_name
    chmod 644 $key_name.pub
}

[ "$action" = "clean" ] && rm -f ${key_name}*
[ "$action" = "generate" ] && generate_keys && action="add"
[ "$action" = "add" ] && ssh-add $key_name

cd $last_dir
