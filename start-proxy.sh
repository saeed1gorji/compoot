#!/usr/bin/env bash

set -e

pushd $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd ) >/dev/null

socks_port=2221
proxy_ssh_port=2223
get_tunnel_pid ()
{
    tunnel_pid=$(ps --no-heading --format pid,cmd | grep -E "ssh.*$socks_port" | grep -v grep | awk '{print $1}')
}

setup_tunnel ()
{
    get_tunnel_pid >/dev/null 2>&1
    if [ -z "$tunnel_pid" ]; then
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
            -N -D $socks_port -p $proxy_ssh_port root@localhost -q & disown
        echo "Socks server has been created."
        get_tunnel_pid >/dev/null 2>&1
        counter=0
        while [ -z "$tunnel_pid" ]; do
            get_tunnel_pid >/dev/null 2>&1
            sleep 0.2
            [ "$counter" -ge 20 ] && echo "Failed creating SSH tunnel! Make sure proxy container is running." && return
            let counter+=1
        done
    fi

    echo "SSH tunnel socks server is running on localhost:$socks_port. (pid=$tunnel_pid)"
}

if [ "$1" = "-t" -o -z "$1"]; then
    # Try setting up the SSH tunnel
    setup_tunnel
    echo "If you wish to setup proxy, enter your password"
    exit 0
fi

proxy_service=ovpn
./ssh-key-manager.sh generate
sudo docker-compose up -d $proxy_service
sudo docker exec $proxy_service connect-vpn $1

final ()
{
    ./ssh-key-manager.sh add
    setup_tunnel
    echo -e "\n\n"
    echo " *** Check logs for connection status: docker logs ${proxy_service}."
    echo " *** SSH tunnel is running on localhost:$socks_port. pid=$tunnel_pid"
    echo -e "\n"
}

trap 'final' EXIT
stty -echoctl
echo -e "\n\n\n"
echo " *** ---->>> Wait for connection success message."
echo " *** ---->>> Use Ctrl+C to escape the log messages."
echo -e "\n\n\n"
sudo docker logs --since "0s" --follow $proxy_service

popd >/dev/null
