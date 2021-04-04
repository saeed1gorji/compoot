#!/usr/bin/env bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Setup loop devices
chmod ug+x $DIR/loop-setup.sh
$DIR/loop-setup.sh $INPUT_DIR

set +e

# Copy config
cp -r /shared/config/* /etc/example/project_config/
