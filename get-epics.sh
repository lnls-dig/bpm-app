#!/usr/bin/env bash

# Check for uninitialized variables
set -u
# Exit on error
set -e

echo "Installing EPICS"

# Source environment variables
. ./env-vars.sh

# Source EPICS variables
. ./epics.sh

USER=$(whoami)
TOP_DIR=$(pwd)
EPICS_ENV_DIR=/etc/profile.d
LDCONF_DIR=/etc/ld.so.conf.d
EPICS_EXTENSIONS_SRC=${EPICS_EXTENSIONS}/src

# Install EPICS base and used modules

# Source repo versions
. ./repo-versions.sh

EPICS_MSI=${EPICS_EXTENSIONS_SRC}/msi${MSI_VERSION}
EPICS_PROCSERV=${EPICS_EXTENSIONS_SRC}/procServ-${PROCSERV_VERSION}
EPICS_SYNAPPS=${EPICS_FOLDER}/synApps_${SYNAPPS_VERSION}/support

if [ "${DOWNLOAD_APP}" == "yes" ]; then
    wget http://www.aps.anl.gov/epics/download/base/baseR${EPICS_BASE_VERSION}.tar.gz
    wget http://www.aps.anl.gov/epics/download/extensions/extensionsTop_${EXTERNSIONS_VERSION}.tar.gz
    wget http://www.aps.anl.gov/epics/download/extensions/msi${MSI_VERSION}.tar.gz
    wget http://downloads.sourceforge.net/project/procserv/${PROCSERV_VERSION}/procServ-${PROCSERV_VERSION}.tar.gz
    wget http://www.aps.anl.gov/bcda/synApps/tar/synApps_${SYNAPPS_VERSION}.tar.gz
fi

############################## EPICS Base #####################################

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing EPICS per user request (-i flag not set)"
    exit 0
fi

# Prepare environment
sudo mkdir -p ${EPICS_FOLDER}
sudo chmod 755 ${EPICS_FOLDER}
sudo chown ${USER}:${USER} ${EPICS_FOLDER}

# Copy EPICS environment variables to profile
sudo cp ${TOP_DIR}/epics.sh ${EPICS_ENV_DIR}
. ${EPICS_ENV_DIR}/epics.sh

# Extract and install EPICS
cd ${EPICS_FOLDER}
tar xvzf ${TOP_DIR}/baseR${EPICS_BASE_VERSION}.tar.gz

# Remove possible existing symlink
rm -f base
# Symlink to EPICS base
ln -sf base-${EPICS_BASE_VERSION} base

# Update ldconfig with EPICS libs
sudo touch ${LDCONF_DIR}/epics.conf
echo "${EPICS_BASE}/lib/${EPICS_HOST_ARCH}" | sudo tee /etc/ld.so.conf.d/epics.conf

# Compile EPICS base
cd ${EPICS_BASE}
make

############################ EPICS Extensions ##################################

# Extract and install extensions
cd ${EPICS_FOLDER}
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
sudo make install

########################### EPICS synApps modules ##############################

cd ${EPICS_FOLDER}
tar xvzf ${TOP_DIR}/synApps_${SYNAPPS_VERSION}.tar.gz

cd ${EPICS_SYNAPPS}

# Fix paths
sed -i -e "s|SUPPORT=.*|SUPPORT=${EPICS_SYNAPPS}|g" \
    -e "s|EPICS_BASE=.*|EPICS_BASE=${EPICS_BASE}|g" configure/RELEASE

make release
make

echo "EPICS installation successfully completed"
