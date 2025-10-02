#!/bin/bash

# Packages required for compilation
export PKG="apr-devel bison bzip2-devel cmake3 flex gcc gcc-c++ krb5-devel \
libcurl-devel libevent-devel libkadm5 libxml2-devel libzstd-devel \
openssl-devel python${PYTHON_VERSON} python3-devel \
python${PYTHON_VERSON}-devel python3-psutil python${PYTHON_VERSON}-pip \
perl-ExtUtils-MakeMaker.noarch perl-ExtUtils-Embed.noarch \
readline-devel rsync xerces-c-devel zlib-devel python3-psutil \
perl perl-interpreter libyaml-devel libuuid-devel \
cyrus-sasl cyrus-sasl-devel openldap-devel postgresql postgresql-devel git"

# Install development tools
dnf group install -y "Development Tools"

# Install packages
dnf install -y ${PKG} && dnf clean all

# Clone WarehousePg repository
git -c http.sslVerify=false clone \
    https://github.com/warehouse-pg/warehouse-pg.git

# Access the repository directory
cd warehouse-pg

# Flags for compilation
export CFLAGS="-Wno-error -O2"
export CXXFLAGS="-std=c++17 -Wno-error"

# Configure (pre compilation)
./configure --prefix=/usr/local/whpg

# Compilation
make

# Install to configured directory
make install

# Generate tarball
tar cvf /tmp/whpg.tar /usr/local/whpg

# Compress the tarball
xz -9 /tmp/whpg.tar
