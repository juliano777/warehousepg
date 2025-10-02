#!/bin/bash

source /etc/profile.d/python.sh

PKG="python${PTYHON_VERSION} python${PTYHON_VERSION}-devel \
python3-psycopg2 python3-pyyaml \
python3-psutil neovim procps-ng apr apr-util bash bzip2 curl \
curl libevent libxml2 libyaml zlib openldap openssl openssl-libs perl \
readline rsync sed tar zip"

tar xf /tmp/whpg.tar.xz -C /

dnf install -y ${PKG}
