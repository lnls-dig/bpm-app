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
    # BPM libs
    git clone --branch=${BPM_SW_LIBS_VERSION} https://github.com/lnls-dig/bpm-sw.git .bpm-sw-libs
fi

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing BPM client dependencies per user request (-i flag not set)"
    exit 0
fi

# Configure and Install
for project in .bpm-sw-libs; do
    cd $project && \
    git submodule update --init --recursive

    # Compile an install dynamic libraries needed by client
    # applications
    for lib in deps liberrhand libconvc libhutils libdisptable libllio libbpmclient; do
        COMMAND="make \
            ERRHAND_DBG=${ERRHAND_DBG} \
            ERRHAND_MIN_LEVEL=${ERRHAND_MIN_LEVEL} \
            ERRHAND_SUBSYS_ON='"${ERRHAND_SUBSYS_ON}"' \
            BOARD=${BOARD} $lib && \
            sudo make ${lib}_install"
        eval $COMMAND

        # Check last command return status
        if [ $? -ne 0 ]; then
            echo "Could not compile/install project $project." >&2
            echo "Try executing the script with root access." >&2
            # Rollback to sane state
            cd ..
            exit 1
        fi
    done

    cd ..
done
