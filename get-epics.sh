#!/usr/bin/env bash

# Check for uninitialized variables
set -u
# Exit on error
set -e

echo "Installing EPICS"

USER=$(whoami)
TOP_DIR=$(pwd)
EPICS_ENV_DIR=/etc/profile.d
LDCONF_DIR=/etc/ld.so.conf.d
EPICS_DIR=/opt/epics
EPICS_BASE=${EPICS_DIR}/base
EPICS_EXTENSIONS=${EPICS_DIR}/extensions
EPICS_EXTENSIONS_SRC=${EPICS_EXTENSIONS}/src
EPICS_MSI=${EPICS_EXTENSIONS_SRC}/msi
EPICS_PROCSERV=${EPICS_EXTENSIONS_SRC}/procServ
EPICS_SYNAPPS=${EPICS_DIR}/synApps/support

# Install EPICS base and used modules

EPICS_BASE_VERSION=3.14.12.4
EXTERNSIONS_VERSION=20120904
MSI_VERSION=1-6
PROCSERV_VERSION=2.6.0
SYNAPPS_VERSION=5_7

if [ $(id -u) -eq 0 ]; then
    echo "This should not be intended to run as root"
    exit 1
fi

wget http://www.aps.anl.gov/epics/download/base/baseR${EPICS_BASE_VERSION}.tar.gz
wget http://www.aps.anl.gov/epics/download/extensions/extensionsTop_${EXTERNSIONS_VERSION}.tar.gz
wget http://www.aps.anl.gov/epics/download/extensions/msi${MSI_VERSION}.tar.gz
wget http://sourceforge.net/projects/procserv/files/${PROCSERV_VERSION}/procServ-${PROCSERV_VERSION}.tar.gz/download
wget http://www.aps.anl.gov/bcda/synApps/tar/synApps_${SYNAPPS_VERSION}.tar.gz

############################## EPICS Base #####################################

# Prepare environment
sudo mkdir ${EPICS_DIR}
sudo chmod 755 ${EPICS_DIR}
sudo chown ${USER}:${USER} ${EPICS_DIR}

# Copy EPICS environment variables to profile
sudo cp ${TOP_DIR}/epics.sh ${EPICS_ENV_DIR}
. ${EPICS_ENV_DIR}/epics.sh

# Extract and install EPICS
cd ${EPICS_DIR}
tar xvzf ${TOP_DIR}/baseR${EPICS_BASE_VERSION}.tar.gz

# Symlink to EPICS base
ln -s baseR${EPICS_BASE_VERSION} base

# Update ldconfig with EPICS libs
sudo touch ${LDCONF_DIR}/epics.conf
sudo echo "${EPICS_BASE}/lib/${EPICS_HOST_ARCH}" > /etc/ld.so.conf.d/epics.conf

# Compile EPICS base
cd ${EPICS_BASE}
make

############################ EPICS Extensions ##################################

# Extract and install extensions
cd ${EPICS_DIR}
tar xvzf ${TOP_DIR}/extensionsTop_${EXTERNSIONS_VERSION}.tar.gz

# Jump to dir and compile
cd ${EPICS_EXTENSIONS}
make
make install

########################### EPICS msi Extension ################################

cd ${EPICS_EXTENSIONS_SRC}
tar xvzf ${TOP_DIR}/msi${MSI_VERSION}.tar.gz

cd ${EPICS_MSI}
make
make install

######################### EPICS procServ Extension #############################

cd ${EPICS_EXTENSIONS_SRC}
tar xvzf ${TOP_DIR}/procServ-${PROCSERV_VERSION}.tar.gz

cd ${EPICS_PROCSERV}
./configure
make
make install

########################### EPICS synApps modules ##############################

cd ${EPICS_DIR}
tar xvzf ${TOP_DIR}/synApps_${SYNAPPS_VERSION}.tar.gz

cd ${EPICS_SYNAPPS}

# Fix paths
sed -i -e "s|SUPPORT=.*|SUPPORT=${EPICS_SYNAPPS}|g" \
    -e "s|EPICS_BASE=.*|EPICS_BASE=${EPICS_BASE}|g" configure/RELEASE

make release
make

echo "EPICS installation successfully completed"
