#!/usr/bin/env bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

# Source environment variables
. ./env-vars.sh

# Source repo versions
. ./repo-versions.sh

BPM_FIRST_ID=1
BPM_LAST_ID=24

if [ "${DOWNLOAD_APP}" == "yes" ]; then
    # HALCS Software
    [[ -d halcs ]] || ./get-repo-and-description.sh -b ${HALCS_VERSION} -r \
        https://github.com/lnls-dig/halcs.git -d halcs -m ${MANIFEST}
fi

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing HALCS server per user request (-i flag not set)"
    exit 0
fi

# Kernel dirs must be set. Otherwise we will get empty values
HALCS_KERNEL_DIR_SET=1
HALCS_DRIVER_INSTALL_DIR_SET=1
HALCS_KERNEL_VERSION_SET=1

# We allow these variables to be uninitialized
set +u
if [ -z "$HALCS_KERNEL_DIR" ]; then
    echo "Environment variable HALCS_KERNEL_DIR unset. Using default /lib/module/$(uname -r)/build"
    HALCS_KERNEL_DIR_SET=0
fi

if [ -z "$HALCS_DRIVER_INSTALL_DIR" ]; then
    echo "Environment variable HALCS_DRIVER_INSTALL_DIR unset. Using default /lib/module/$(uname -r)/extra"
    HALCS_DRIVER_INSTALL_DIR_SET=0
fi

if [ -z "$HALCS_KERNEL_VERSION" ]; then
    echo "Environment variable HALCS_KERNEL_VERSION unset. Using default $(uname -r)"
    HALCS_KERNEL_VERSION_SET=0
fi
set -u

HALCS_EXTRA_FLAGS=("")
# Configure and Install
for project in halcs; do
    cd $project && \
    git submodule update --init --recursive && \

    # Use passed kernel variables
    if [ "$HALCS_KERNEL_DIR_SET" -eq "1" ]; then
        HALCS_EXTRA_FLAGS+=("KERNELDIR=${HALCS_KERNEL_DIR}")
    fi

    if [ "$HALCS_DRIVER_INSTALL_DIR_SET" -eq "1" ]; then
        HALCS_EXTRA_FLAGS+=("INSTALLDIR=${HALCS_DRIVER_INSTALL_DIR}")
    fi

    if [ "$HALCS_KERNEL_VERSION_SET" -eq "1" ]; then
        HALCS_EXTRA_FLAGS+=("KERNEL_VERSION=${HALCS_KERNEL_VERSION}")
    fi

    sudo ./gradle_compile.sh -b ${BOARD} -a ${HALCS_APPS} -e ${HALCS_WITH_EXAMPLES} \
        -l ${HALCS_WITH_SYSTEM_INTEGRATION} -d ${HALCS_WITH_DRIVER} -x \
       "${HALCS_EXTRA_FLAGS[*]}" && \
    cd ..

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project $project." >&2
        echo "Try executing the script with root access." >&2
        exit 1
    fi

   # Enable all possible instances
   for i in `seq ${BPM_FIRST_ID} ${BPM_LAST_ID}`; do
       systemctl enable halcs-be@${i}
       systemctl enable halcs-fe@${i}
       systemctl enable halcs-be-ioc@${i}
       systemctl enable halcs-fe-ioc@${i}
   done
done
