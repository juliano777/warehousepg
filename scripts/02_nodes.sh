#!/bin/bash

source /etc/profile.d/python.sh

PKG="python${PTYHON_VERSION} python${PTYHON_VERSION}-devel \
procps-ng apr apr-util bash bzip2 curl \
curl libevent libxml2 libyaml zlib openldap openssl openssl-libs perl \
readline rsync sed tar zip"

tar xf /tmp/whpg.tar.xz -C /

dnf install -y ${PKG}
