#!/usr/bin/env bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

# Source environment variables
. ./env-vars.sh

# Source repo versions
. ./repo-versions.sh

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
if [ -z "$HALCS_KERNEL_DIR" ]; then
    echo "Environment variable HALCS_KERNEL_DIR unset."
    exit 1
fi

if [ -z "$HALCS_DRIVER_INSTALL_DIR" ]; then
    echo "Environment variable HALCS_DRIVER_INSTALL_DIR unset."
    exit 1
fi

# Configure and Install
for project in halcs; do
    cd $project && \
    git submodule update --init --recursive && \
    sudo ./compile.sh -b ${BOARD} -a ${HALCS_APPS} -e ${HALCS_WITH_EXAMPLES} \
        -l ${HALCS_WITH_SYSTEM_INTEGRATION} -d ${HALCS_WITH_DRIVER} -x \
        "KERNELDIR=${HALCS_KERNEL_DIR} INSTALLDIR=${HALCS_DRIVER_INSTALL_DIR}" && \
    cd ..

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project $project." >&2
        echo "Try executing the script with root access." >&2
        exit 1
    fi
done
