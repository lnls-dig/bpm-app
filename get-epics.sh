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
    wget -nc http://www.aps.anl.gov/epics/download/base/baseR${EPICS_BASE_VERSION}.tar.gz
    wget -nc http://www.aps.anl.gov/epics/download/extensions/extensionsTop_${EXTERNSIONS_VERSION}.tar.gz
    wget -nc http://www.aps.anl.gov/epics/download/extensions/msi${MSI_VERSION}.tar.gz
    wget -nc http://downloads.sourceforge.net/project/procserv/${PROCSERV_VERSION}/procServ-${PROCSERV_VERSION}.tar.gz
    wget -nc http://www.aps.anl.gov/bcda/synApps/tar/synApps_${SYNAPPS_VERSION}.tar.gz
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
echo "${EPICS_BASE}/lib/${EPICS_HOST_ARCH}" | sudo tee -a /etc/ld.so.conf.d/epics.conf
echo "/usr/lib64" | sudo tee -a /etc/ld.so.conf.d/epics.conf
echo "/lib64" | sudo tee -a /etc/ld.so.conf.d/epics.conf
echo "/usr/lib" | sudo tee -a /etc/ld.so.conf.d/epics.conf

# Update ldconfig cache
sudo ldconfig

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

# Fix ADCore paths
sed -i \
    -e "s|HDF5\( *\)=.*|HDF5\1= ${HDF5_BASE}|g" \
    -e "s|HDF5_LIB\( *\)=.*|HDF5_LIB\1= ${HDF5_LIB}|g" \
    -e "s|HDF5_INCLUDE\( *\)=.*|HDF5_INCLUDE\1= -I${HDF5_INCLUDE}|g" \
    -e "s|SZIP\( *\)=.*|SZIP\1= ${SZIP_BASE}|g" \
    -e "s|SZIP_LIB\( *\)=.*|SZIP_LIB\1= ${SZIP_LIB}|g" \
    -e "s|SZIP_INCLUDE\( *\)=.*|SZIP_INCLUDE\1= -I${SZIP_INCLUDE}|g" \
    -e "s|GRAPHICS_MAGICK\( *\)=.*|GRAPHICS_MAGICK\1= ${GRAPHICS_MAGICK_BASE}|g" \
    -e "s|GRAPHICS_MAGICK_LIB\( *\)=.*|GRAPHICS_MAGICK_LIB\1= ${GRAPHICS_MAGICK_LIB}|g" \
    -e "s|GRAPHICS_MAGICK_INCLUDE\( *\)=.*|GRAPHICS_MAGICK_INCLUDE\1= -I${GRAPHICS_MAGICK_INCLUDE}|g" \
    areaDetector-R2-0/configure/CONFIG_SITE.local.linux-x86_64

# Change some modules to dynamic link to libhdf5 and libsz.
# For some reason, we don't have the static versions of them
# and the compilation fails with:
# /bin/ld: cannot find -lhdf5
# /bin/ld: cannot find -lsz
sed -i \
    -e "s|STATIC_BUILD=YES|STATIC_BUILD=NO|g" \
    quadEM-5-0/configure/CONFIG_SITE

sed -i \
    -e "s|STATIC_BUILD=YES|STATIC_BUILD=NO|g" \
    dxp-3-4/configure/CONFIG_SITE

# EPICS synApps R5_8 does not search hdf5 headers in /usr/include/hdf5/serial,
# which is where Ubuntu 16.04 installs them. Symlink them to /usr/include
sudo ln -sf /usr/include/hdf5/serial/*.h /usr/include/ || /bin/true
# Create symlinks so linker can find it
sudo ln -sf ${SZIP_LIB}/libsz.so.2 ${SZIP_LIB}/libsz.so || /bin/true

# Debug/Info stuff
echo "======= configure/RELEASE.local ========================================="
cat configure/RELEASE.local || /bin/true

echo "======= configure/RELEASE ==============================================="
cat configure/RELEASE

echo "======= configure/CONFIG_SITE.linux-x86_64.Common ======================="
cat configure/CONFIG_SITE.linux-x86_64.Common || /bin/true

make release
make

echo "EPICS installation successfully completed"
