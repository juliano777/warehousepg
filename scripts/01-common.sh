#!/bin/bash

# Update the system ----------------------------------------------------------

# EPEL repository
dnf install -y epel-release

# Update the system
dnf update -y

# Python ---------------------------------------------------------------------
# Set Python version
export PYTHON_VERSON='3.9'

# Install Python
dnf install -y python${PYTHON_VERSON}

# Python binary
export PYTHON="/usr/bin/python${PYTHON_VERSON}"

# Update alternatives regarding Python
update-alternatives --install /usr/bin/python3 python3 ${PYTHON} 1
update-alternatives --install /usr/bin/python3 python ${PYTHON} 1
update-alternatives --set python3 ${PYTHON}
update-alternatives --set python ${PYTHON}

# Python script to get PYTHONPATH
cat << EOF > /usr/local/bin/get_pythonpath && \
chmod +x /usr/local/bin/get_pythonpath
#!/usr/bin/env python
from sys import path

# List comprehension to get PYTHONPATH
pythonpath = ':'.join([i for i in path if i != ''])

# Print the variable
print(pythonpath)
EOF

# Profile script
cat << EOF > /etc/profile.d/python.sh 
# Python environment variables
export PYTHON_VERSON='${PYTHON_VERSON}'

# Python binary
export PYTHON='/usr/bin/python${PYTHON_VERSON}'

EOF

# Packages -------------------------------------------------------------------

# Package list to be installed
PKG="xerces-c neovim bash-completion procps-ng util-linux sudo tree rsync \
openssh-clients openssh-server iproute python${PYTHON_VERSON}-setuptools \
python${PYTHON_VERSON}-psycopg2 python${PYTHON_VERSON}-pyyaml python3-psutil"

# Install some packages and clear downloaded packages
dnf install -y ${PKG} && dnf clean all
