#!/bin/sh

set -e

# Example: Sets DNS when tun device is set up. $dev would be the tun device in use.
# This example works on debian/ubuntu. Other distributions might use other methods.
resolvectl domain $dev "~example.com"
resolvectl dns $dev "192.168.1.100"
