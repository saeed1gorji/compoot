#!/usr/bin/env bash

proxy_service=ovpn
proxy_prog_name=openvpn
ping_url=example.com

socks_port=2221
pid=$(ps --no-heading --format pid,cmd | grep -E "ssh.*$socks_port" | grep -v grep | tr -s ' ' | sed 's/^ *//g' | cut -d' ' -f1)

echo -e "\n"
echo "--- OpenVPN process status:"
sudo docker exec $proxy_service ps -a | grep -ve "grep\|ps -a" | grep $proxy_prog_name

echo -e "\n"
echo "--- Ping status:"
sudo docker exec $proxy_service ping -c2 $ping_url

echo -e "\n"
echo "--- Container status:"
sudo docker container ps -a | grep $proxy_service

echo -e "\n"
echo "--- SSH tunnel socks server status:"
if [ ! -z "$pid" ]; then
    echo "Socks server is running on port $socks_port. (pid=$pid)"
else
    echo "Socks server is down."
fi
