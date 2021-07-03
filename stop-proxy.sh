#!/usr/bin/env bash

set -e

pushd $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd ) >/dev/null

proxy_service=ovpn

socks_port=2221
ssh_port=2223
pid=$(ps --no-heading --format pid,cmd | grep -E "ssh.*$socks_port" | grep -v grep | awk '{print $1}')
if [ ! -z "$pid" ]; then
    kill -15 $pid
    echo "SSH tunnel (pid=$pid) terminated."
fi

function stop_service()
{
    set +e
    sudo docker exec $proxy_service pkill -15 openvpn 2>/dev/null
    sudo docker exec $proxy_service service sshd stop 2>/dev/null
    [ $? -eq 1 ] && echo "$proxy_service is already down." && [ ! "$1" = "restart" ] && exit 0
    set -e
}

if [ "all" = "$1" -o "down" = "$1" ]; then
    sudo docker-compose down --timeout=2
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[localhost]:$ssh_port"
elif [ "restart" = "$1" ]; then
    stop_service
    sudo docker-compose restart --timeout=2 $proxy_service
else
    stop_service
    sudo docker-compose stop --timeout=2 $proxy_service
fi

popd >/dev/null
