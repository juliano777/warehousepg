#!/bin/bash

# Read variables from global Python profile script
source /etc/profile.d/python.sh

# Package list to be installed
PKG="python${PYTHON_VERSION} python${PYTHON_VERSION}-devel \
procps-ng apr apr-util bash bzip2 curl \
curl libevent libxml2 libyaml zlib openldap openssl openssl-libs perl \
readline rsync sed tar zip wget"

# Decompress the compiled WarhousePg
tar xf /tmp/whpg.tar.xz -C /

# Install the packages
dnf install -y ${PKG}

# gpadmin system user --------------------------------------------------------

# Group creation
groupadd -r gpadmin

# User creation
useradd \
    -s /bin/bash \
    -md /var/local/whpg \
    -k /etc/skel \
    -g gpadmin \
    -G wheel \
    -c 'Greenplum admin WarehousePG user' \
    -r gpadmin

# Generate SSH keys for gpadmin
if [ ! -f ~gpadmin/.ssh/id_rsa ]; then
    su - gpadmin -c "ssh-keygen -t rsa -b 4096 -P '' -f ~/.ssh/id_rsa";
fi
