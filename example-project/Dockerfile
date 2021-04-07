# Note: All requirements of creating the containers are specified in docker-compose file.

ARG APT_INSTALL_OPTS="-y --no-install-recommends --no-install-suggests"
ARG DEBIAN_FRONTEND=noninteractive

FROM ubuntu:focal as base

WORKDIR /root/
ARG TZ
ARG APT_INSTALL_OPTS
ARG DEBIAN_FRONTEND

# Configure apt, set tz, update index
COPY ./apt-config/sources.list /etc/apt/sources.list
RUN apt update #--allow-insecure-repositories
RUN ln -snf /usr/share/zoneinfo/$TZ_SELECT /etc/localtime && \
    echo $TZ_SELECT > /etc/timezone

# Install project dependecies
COPY ./deb-dependencies /pkg-list
RUN cat /pkg-list | xargs apt install $APT_INSTALL_OPTS && \
    rm /pkg-list

CMD bash

#####################
FROM base as test

WORKDIR /root/
ARG APT_INSTALL_OPTS
ARG DEBIAN_FRONTEND
ARG PROJECT_NAME

# Build and install from source
ARG SOURCE_DIR=/root/$PROJECT_NAME
RUN echo $SOURCE_DIR
COPY ./projects/$PROJECT_NAME $SOURCE_DIR
WORKDIR $SOURCE_DIR
RUN apt install make $APT_INSTALL_OPTS && \
    cd $PROJECT_NAME && \
    ./setup.py install && \
    cd ../${PROJECT_NAME}-udebs && \
    make && make install
WORKDIR /root/
# Or install from offline deb packages
#RUN apt install /shared/packages/*.deb $APT_INSTALL_OPTS

# Startup
ENV STARTUP_SCRIPT=/shared/scripts/startup-test.sh
CMD $STARTUP_SCRIPT; $CUSTOM_CMD
#CMD chmod ug+x $STARTUP_SCRIPT && $STARTUP_SCRIPT; bash -c "$CUSTOM_CMD"; bash

# Handled by compose or cli run/create:
# - Setting build command env var
# - Sharing the source directories
# - Use of a proxy container network to access VPN

#####################
FROM base as develop

WORKDIR /root/
ARG APT_INSTALL_OPTS
ARG DEBIAN_FRONTEND

# Install needed tools
COPY ./deb-development /pkg-list
RUN cat /pkg-list | xargs apt install $APT_INSTALL_OPTS && \
    rm /pkg-list

# Config SSH and change root password (for SSH login)
ARG ROOT_PASSWD=a
ARG SSHD_CONFIG="/etc/ssh/sshd_config"
RUN sed "/#PermitRootLogin/d" -i $SSHD_CONFIG && \
    echo 'PermitRootLogin yes' >> $SSHD_CONFIG && \
    sed '/#PasswordAuthentication/d' -i $SSHD_CONFIG && \
    echo 'PasswordAuthentication yes' >> $SSHD_CONFIG && \
    echo root:$ROOT_PASSWD | chpasswd

# Startup
ENV STARTUP_SCRIPT=/shared/scripts/startup-dev.sh
CMD $STARTUP_SCRIPT; service ssh restart; bash

# Handled by compose or cli run/create:
# - Setiing build command env var
# - Sharing the source directories
# - Use of a proxy container network to access VPN
