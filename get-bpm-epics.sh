#!/usr/bin/env bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

# Source environment variables
. ./env-vars.sh

# Source epics-dev environment variables.
# This may overwrite some variables
. ./foreign/epics-dev/env-vars.sh

# Source repo versions
. ./repo-versions.sh

if [ "${DOWNLOAD_APP}" == "yes" ]; then
    [[ -d bpm-epics-ioc ]] || ./get-repo-and-description.sh -b ${BPM_EPICS_IOC_VERSION} -r \
        https://github.com/lnls-dig/bpm-epics-ioc.git -d bpm-epics-ioc -m ${MANIFEST}
fi

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing BPM EPICS IOC per user request (-i flag not set)"
    exit 0
fi

# Configure and Install IOC BPM
for project in bpm-epics-ioc; do
    cd $project && \
    git submodule update --init --recursive

    # Fix ADCore library paths
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
        configure/CONFIG_SITE

    # Install it
    make && \
    sudo make install && \
    cd ..

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project $project." >&2
        echo "Try executing the script with root access." >&2
        exit 1
    fi

    # Enable all possible instances
    for i in `seq ${BPM_FIRST_ID} ${BPM_LAST_ID}`; do
        systemctl enable halcs-be-ioc@${i} || /bin/true
        systemctl enable halcs-fe-ioc@${i} || /bin/true
    done

done
