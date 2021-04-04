#!/usr/bin/env bash

proxy_service=ovpn
proxy_prog_name=openvpn

socks_port=2221
pid=$(ps --no-heading --format pid,cmd | grep -E "ssh.*$socks_port" | grep -v grep | tr -s ' ' | sed 's/^ *//g' | cut -d' ' -f1)

sudo docker exec $proxy_service ps -a | grep -ve "grep\|ps -a" | grep $proxy_prog_name
sudo docker exec $proxy_service ping -c2 example.com

echo -e "\n"
sudo docker container ps -a | grep $proxy_service

echo -e "\n"
if [ ! -z "$pid" ]; then
    echo "Socks server is running on port $socks_port. (pid=$pid)"
else
    echo "Socks server is down."
fi
