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
tar xvf szip-${SZIP_VERSION}.tar.gz
cd szip-${SZIP_VERSION}

./configure --libdir=${SZIP_LIB} --includedir=${SZIP_INCLUDE}
make
sudo make install

cd ..

# Add symlinks. This won't work as this link is only done
# in the host image and not the generated one.
sudo ln -sf ${SZIP_LIB}/libsz.so.2 ${SZIP_LIB}/libsz.so || /bin/true
