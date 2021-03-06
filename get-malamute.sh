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
    [[ -d malamute  ]] || ./get-repo-and-description.sh -b ${MALAMUTE_VERSION} -r \
        https://github.com/lnls-dig/malamute.git -d malamute -m ${MANIFEST}
fi

# Patch repos
if [ "${DOWNLOAD_APP}" == "yes" ]; then
    # Patch malamute repository to avoid filling logsystem with dummy messages
    if ([ "${MALAMUTE_VERSION}" \> "v1.0" ] || [ "${MALAMUTE_VERSION}" == "v1.0" ]) && \
        [ "${MALAMUTE_VERSION}" \< "v1.6.1" ]; then
        echo "MALAMUTE version ${MALAMUTE_VERSION} will be patched"
        cd malamute
        git am --ignore-whitespace ../patches/malamute/*
        cd ../
    fi
fi

if [ "${INSTALL_APP}" == "no" ]; then
    # Good for debug
    echo "Not installing BPM dependencies per user request (-i flag not set)"
    exit 0
fi

# Configure and Install
for project in malamute; do

    CONFIG_OPTS=()
    CONFIG_OPTS+=("--with-systemd-units")
    CONFIG_OPTS+=("--sysconfdir=/usr/etc")
    CONFIG_OPTS+=("--prefix=/usr")
    CONFIG_OPTS+=("CFLAGS=-Wno-format-truncation")
    CONFIG_OPTS+=("CPPFLAGS=-Wno-format-truncation")

    cd $project && \
    ./autogen.sh && \
    ./configure "${CONFIG_OPTS[@]}" && \
    make check && \
    make && \
    sudo make install && \
    sudo ldconfig && \
    cd ..

    MALAMUTE_VERBOSE=0
    MALAMUTE_PLAIN_AUTH=
    MALAMUTE_AUTH_MECHANISM=null
    MALAMUTE_ENDPOINT='ipc:///tmp/malamute'
    MALAMUTE_CFG_FILE=/usr/etc/malamute/malamute.cfg
    # Install our custom Malamute config file
    sudo sed -i \
        -e "s|verbose\( *\)=.*|verbose\1= ${MALAMUTE_VERBOSE}|g" \
        -e "s|plain\( *\)=.*|plain\1= ${MALAMUTE_PLAIN_AUTH}|g" \
        -e "s|mechanism\( *\)=.*|mechanism\1= ${MALAMUTE_AUTH_MECHANISM}|g" \
        -e "s|tcp://\*:9999|${MALAMUTE_ENDPOINT}|g" \
        ${MALAMUTE_CFG_FILE}


    # Enable service
    sudo systemctl enable malamute || /bin/true

    # add environment variables for malamute
    sudo bash -c "echo export ZSYS_LOGSYSTEM=false >> /etc/profile.d/malamute.sh"

	mkdir -p /etc/systemd/system/malamute.service.d
	cat << EOF > /etc/systemd/system/malamute.service.d/override.conf
[Service]
Environment=\"ZSYS_LOGSYSTEM=false\"
EOF

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project $project." >&2
        echo "Try executing the script with root access." >&2
        exit 1
    fi
done
