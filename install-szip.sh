#!/bin/sh

set -e
set -x

# Source environment variables
. ./env-vars.sh

# Source repo versions
. ./repo-versions.sh

# Download RPM
wget https://support.hdfgroup.org/ftp/lib-external/szip/2.1.1/src/szip-${SZIP_VERSION}.tar.gz

# Install it
cd szip-${SZIP_VERSION}

./configure --prefix=${SZIP_BASE}
make
sudo make install

cd ..

# Add symlinks. This won't work as this link is only done
# in the host image and not the generated one.
sudo ln -sf /usr/lib64/libsz.so.2 /usr/lib64/libsz.so || /bin/true
