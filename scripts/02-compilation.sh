#!/bin/bash

# Packages required for compilation
export PKG="apr-devel bison bzip2-devel cmake3 flex gcc gcc-c++ krb5-devel \
libcurl-devel libevent-devel libkadm5 libxml2-devel libzstd-devel \
openssl-devel python3-devel python${PYTHON_VERSON}-devel python3-psutil \
python${PYTHON_VERSON}-pip perl-ExtUtils-MakeMaker.noarch \
perl-ExtUtils-Embed.noarch readline-devel rsync xerces-c-devel zlib-devel \
python3-psutil perl perl-interpreter libyaml-devel libuuid-devel \
cyrus-sasl cyrus-sasl-devel openldap-devel git"

# Install development tools
dnf group install -y "Development Tools"

# Enable the "PowerTools" (now known as CRB - CodeReady Builder) repository:
dnf config-manager --set-enabled crb

# Install packages
dnf install -y ${PKG} && dnf clean all

# Clone WarehousePg repository
git clone https://github.com/warehouse-pg/warehouse-pg.git

# Access the repository directory
cd warehouse-pg

# PYTHONPATH
export PYTHONPATH="`/usr/local/bin/get_pythonpath`"

# Flags for compilation
CPPFLAGS="-DLINUX_OOM_SCORE_ADJ=0"

NJOBS=`expr \`nproc\` + 1`

MAKEOPTS="-j${NJOBS}"

CHOST="`arch`-unknown-linux-gnu"

CFLAGS='-O2 -pipe -march=native'

# Configure (pre compilation)
./configure --prefix=/usr/local/whpg --with-python --host=${CHOST}

# Compilation
#make world
make

# Install to configured directory
make install

# Generate tarball
tar cvf /tmp/whpg.tar /usr/local/whpg

# Compress the tarball
xz -9 /tmp/whpg.tar
