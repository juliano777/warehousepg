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
