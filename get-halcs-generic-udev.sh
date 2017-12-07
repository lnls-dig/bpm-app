# Exit on error
set -e
# Check for uninitialized variables
set -u

# Source environment variables
. ./env-vars.sh

# Source repo versions
. ./repo-versions.sh

if [ "${DOWNLOAD_APP}" == "yes" ]; then
    # HALCS_GENERIC_UDEV Software
    [[ -d halcs-generic-udev ]] || ./get-repo-and-description.sh -b ${HALCS_GENERIC_UDEV_VERSION} -r \
        https://github.com/lnls-dig/halcs-generic-udev.git -d halcs-generic-udev -m ${MANIFEST}
fi

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing HALCS_GENERIC_UDEV server per user request (-i flag not set)"
    exit 0
fi

# Configure and Install HALCS_GENERIC_UDEV_VERSION
for project in halcs-generic-udev; do
    cd $project && \
    git submodule update --init --recursive

    # Install it
    sudo make install && \
    cd ..

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project $project." >&2
        echo "Try executing the script with root access." >&2
        exit 1
    fi
done
