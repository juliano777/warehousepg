#!/bin/bash

source /etc/profile.d/python.sh

PKG="python${PTYHON_VERSION} python${PTYHON_VERSION}-devel \
python${PTYHON_VERSION}-psycopg2 python${PTYHON_VERSION}-pyyaml \
python${PTYHON_VERSION}-psutil neovim procps-ng apr apr-util bash bzip2 curl \
libcurl libevent libxml2 libyaml zlib openldap openssl openssl-libs perl \
readline rsync sed tar zip"

tar xf /tmp/whpg.tar.xz -C /

dnf install -y ${PKG}
