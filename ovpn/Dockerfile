FROM alpine

# Install openvpn and needed utilities
ARG APK_OPTS="--no-cache --no-progress"
RUN apk $APK_OPTS upgrade && \
    apk $APK_OPTS add bash curl openvpn openrc openssh-server && \
    rm -rf /tmp/*

# Config SSH and change root password (for SSH login)
ARG SSHD_CONFIG=/etc/ssh/sshd_config
RUN sed 's/#Port 22/Port 23/g' -i $SSHD_CONFIG && \
    sed "/#PermitRootLogin/d" -i $SSHD_CONFIG && \
    echo 'PermitRootLogin prohibit-password' >> $SSHD_CONFIG && \
    sed '/#PasswordAuthentication/d' -i $SSHD_CONFIG && \
    echo 'PasswordAuthentication no' >> $SSHD_CONFIG && \
    sed 's/AllowTcpForwarding no/AllowTcpForwarding yes/g' -i $SSHD_CONFIG && \
    # Unlock root to allow ssh login
    sed -i 's/^root:!/root:/' /etc/shadow

# Setup ssh daemon with openrc
RUN rc-status && \
    touch /run/openrc/softlevel && \
    rc-update add sshd
ENV STARTUP_SCRIPT=/shared/scripts/startup.sh

# ENTRYPOINT is supposed to be set to tini (or docker-init). This is done by --init flag passed by docker compose or other run commands.
# CMD uses exec form to avoid running a master shell process that could take PID 1.
# A final /bin/sh is issued to keep container idle (otherwise stops immediately).
# Bash or busybox will ignore SIGTERM. Docker stop first sends SIGTERM and waits 10s by default.
# If container doesn't stop, docker will send a SIGKILL, forcing the container to stop.
# Since a /bin/sh process is always up and running and only terminates with SIGKILL, use --time=3 or less with docker stop.
CMD ["sh", "-c", "$STARTUP_SCRIPT; service sshd restart; /bin/sh"]

# Install and configure vpn user data
ARG OVPN_PATH="/etc/openvpn"
ARG OVPN_CONF=${OVPN_PATH}/user.ovpn
COPY ./openvpn/* ${OVPN_PATH}/
RUN sed -i '/^up \|^down /d' $OVPN_CONF          && \
    echo up ${OVPN_PATH}/up.sh >> $OVPN_CONF     && \
    echo down ${OVPN_PATH}/down.sh >> $OVPN_CONF

# Make container health instpectable
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s \
             CMD curl -LSs 'https://api.ipify.org'
