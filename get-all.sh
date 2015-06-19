#!/usr/bin/env bash

# Our options
BPM_SW_BOARD=afcv3
BPM_SW_WITH_EXAMPLES="with_examples"
BPM_SW_CLI_PREFIX=/usr/local

VALID_ROLES_STR="Valid values are: \"server\", \"client\" or \"gateware\"."

# Select if we are deploying in server or client: server or client
ROLE=$1

if [ -z "$ROLE" ]; then
    echo "\"ROLE\" variable unset. "$VALID_ROLES_STR
    exit 1
fi

if [ "$ROLE" != "server" ] && [ "$ROLE" != "client" ] && [ "$ROLE" != "gateware" ]; then
    echo "Unsupported role. "$VALID_ROLES_STR
    exit 1
fi

# Both server and client needs these libraries
if [ "$ROLE" == "server" ] || [ "$ROLE" == "client" ]; then
    # ZEROmq libraries
    git clone --branch=1.0.3 git://github.com/jedisct1/libsodium.git
    git clone --branch=master git://github.com/zeromq/libzmq.git
    git clone --branch=v3.0.2 git://github.com/zeromq/czmq.git
    git clone --branch=v0.1.0 git://github.com/lnls-dig/malamute.git

    # Configure and Install
    for project in libsodium libzmq czmq malamute; do
        cd $project && \
        ./autogen.sh && \
        ./configure &&
        make check && \
        make install && \
        ldconfig && \
        cd ..

        # Check last command return status
        if [ $? -ne 0 ]; then
            echo "Could not compile/install project $project." >&2
            echo "Try executing the script with root access." >&2
            exit 1
        fi
    done
fi

# Server
if [ "$ROLE" == "server" ]; then
    # BPM Software
    git clone --branch=v0.1 git://github.com/lnls-dig/bpm-sw.git

    # Configure and Install
    for project in bpm-sw; do
        cd $project && \
        git submodule update --init --recursive && \
        ./compile.sh ${BPM_SW_BOARD} ${BPM_SW_WITH_EXAMPLES} && \
        cd ..

        # Check last command return status
        if [ $? -ne 0 ]; then
            echo "Could not compile/install project $project." >&2
            echo "Try executing the script with root access." >&2
            exit 1
        fi
    done
fi

# BPM client lib flags
BOARD_VAL=afcv3
ERRHAND_DBG_VAL=y
ERRHAND_MIN_LEVEL_VAL=DBG_LVL_INFO
ERRHAND_SUBSYS_ON_VAL='"(DBG_DEV_MNGR | DBG_DEV_IO | DBG_SM_IO | DBG_LIB_CLIENT | DBG_SM_PR | DBG_SM_CH | DBG_LL_IO | DBG_HAL_UTILS)"'

# Client
if [ "$ROLE" == "client" ]; then
    # BPM libbpmclient
    git clone --branch=v0.1 git://github.com/lnls-dig/bpm-sw.git .bpm-sw-libs

    # Configure and Install
    for project in .bpm-sw-libs; do
        cd $project && \
        git submodule update --init --recursive

        # Compile an install dynamic libraries needed by client
        # applications
        for lib in liberrhand libhutils libbpmclient; do
            COMMAND="make \
                ERRHAND_DBG=${ERRHAND_DBG_VAL} \
                ERRHAND_MIN_LEVEL=${ERRHAND_MIN_LEVEL_VAL} \
                ERRHAND_SUBSYS_ON='"${ERRHAND_SUBSYS_ON_VAL}"' \
                BOARD=${BOARD_VAL} $lib && \
                make ${lib}_install"
            eval $COMMAND

            # Check last command return status
            if [ $? -ne 0 ]; then
                echo "Could not compile/install project $project." >&2
                echo "Try executing the script with root access." >&2
                exit 1
            fi
        done

        cd ..
    done

    # BPM Client Software
    git clone --branch=v0.1.2 git://github.com/lnls-dig/bpm-sw-cli.git

    # Configure and Install
    for project in bpm-sw-cli; do
        cd $project && \
        git submodule update --init --recursive && \
        ./compile.sh ${BPM_SW_CLI_PREFIX} && \
        cd ..

        # Check last command return status
        if [ $? -ne 0 ]; then
            echo "Could not compile/install project $project." >&2
            echo "Try executing the script with root access." >&2
            exit 1
        fi
    done
fi

# Gateware
if [ "$ROLE" == "gateware" ]; then
    # BPM Gateware
    git clone --branch=v0.1 git://github.com/lnls-dig/bpm-gw.git
    # BPM IPMI
    git clone --branch=v0.1 git://github.com/lnls-dig/bpm-ipmi.git

    # Configure and Install
    for project in bpm-gw bpm-ipmi; do
        cd $project && \
        git submodule update --init --recursive && \
        cd ..

        # Check last command return status
        if [ $? -ne 0 ]; then
            echo "Could not compile/install project $project." >&2
            echo "Try executing the script with root access." >&2
            exit 1
        fi
    done
fi
