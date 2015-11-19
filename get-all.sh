#!/usr/bin/env bash

# Exit on error
set -e

# Our options
BPM_SW_BOARD=afcv3
BPM_SW_WITH_EXAMPLES="with_examples"
BPM_SW_CLI_PREFIX=/usr/local

VALID_ROLES_STR="Valid values are: \"server\", \"client\" or \"gateware\"."
VALID_BOARDS_STR="Valid values are: \"ml605\" and \"afcv3\"."
VALID_AUTOTOOLS_CFG_STR="Valid values are: \"with_autotools\" and \"without_autotools\"."
VALID_EPICS_CFG_STR="Valid values are: \"with_epics\" and \"without_epics\"."

function usage {
    echo "Usage: $0 -r <role = [server|client|gateware]> -b <board =[ml605|afcv3]> -a <install autotools> -e <install EPICS tools> "
}

# Select if we are deploying in server or client: server or client
ROLE=
# Select board in which we will work. Options are: ml605 or afcv3
BOARD=
# Select if we want autotools or not. Options are: yes or no
AUTOTOOLS_CFG="no"
# Select if we want epics or not. Options are: with_epics or without_epics
EPICS_CFG="no"

# Get command line options
while getopts ":r:b:ae" opt; do
    case $opt in
        r)
            ROLE=$OPTARG
            ;;
        b)
            BOARD=$OPTARG
            ;;
        a)
            AUTOTOOLS_CFG="yes"
            ;;
        e)
            EPICS_CFG="yes"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

if [ -z "$ROLE" ]; then
    echo "Option \"-r\" unset. "$VALID_ROLES_STR
    usage
    exit 1
fi

if [ "$ROLE" != "server" ] && [ "$ROLE" != "client" ] && [ "$ROLE" != "gateware" ]; then
    echo "Option \"-r\" has unsupported role. "$VALID_ROLES_STR
    usage
    exit 1
fi

if [ -z "$BOARD" ] && [ "$ROLE" != "gateware" ]; then
    echo "Option \"-b\" unset. "$VALID_BOARDS_STR
    usage
    exit 1
fi

if [ "$BOARD" != "afcv3" ] && [ "$BOARD" != "ml605" ] && [ "$ROLE" != "gateware" ]; then
    echo "Option \"-b\" has unspported board. "$VALID_BOARDS_STR
    usage
    exit 1
fi

# Check for uninitialized variables
set -u

######################## System Dependencies Installation ######################
./get-system-deps.sh

########################### Dependencies Installation ##########################

# Check if we want to install autotools
if [ "$AUTOTOOLS_CFG" == "yes" ]; then
    ./get-autotools.sh

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project autotools." >&2
        exit 1
    fi
fi

# Check if we want to install epics
if [ "$EPICS_CFG" == "yes" ]; then
    ./get-epics.sh

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project epics." >&2
        exit 1
    fi
fi

################################## BPM SW #####################################

# Both server and client needs these libraries
if [ "$ROLE" == "server" ] || [ "$ROLE" == "client" ]; then
    # ZEROmq libraries
    git clone --branch=1.0.3 git://github.com/jedisct1/libsodium.git
    git clone --branch=master git://github.com/zeromq/libzmq.git
    git clone --branch=v3.0.2 git://github.com/zeromq/czmq.git
    git clone --branch=v0.1.1 git://github.com/lnls-dig/malamute.git

    # Configure and Install
    for project in libsodium libzmq czmq malamute; do
        cd $project && \
        ./autogen.sh && \
        ./configure &&
        make check && \
        make && \
        sudo make install && \
        sudo ldconfig && \
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
#    git clone --branch=v0.1 git://github.com/lnls-dig/bpm-sw.git
    git clone --branch=devel git://github.com/lnls-dig/bpm-sw.git

    # Configure and Install
    for project in bpm-sw; do
        cd $project && \
        git submodule update --init --recursive && \
        sudo ./compile.sh ${BPM_SW_BOARD} ${BPM_SW_WITH_EXAMPLES} && \
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
BOARD_VAL=${BOARD}
ERRHAND_DBG_VAL=y
ERRHAND_MIN_LEVEL_VAL=DBG_LVL_INFO
ERRHAND_SUBSYS_ON_VAL='"(DBG_DEV_MNGR | DBG_DEV_IO | DBG_SM_IO | DBG_LIB_CLIENT | DBG_SM_PR | DBG_SM_CH | DBG_LL_IO | DBG_HAL_UTILS)"'

# Client
if [ "$ROLE" == "client" ]; then
    # BPM libbpmclient
#    git clone --branch=v0.1 git://github.com/lnls-dig/bpm-sw.git .bpm-sw-libs
    git clone --branch=devel git://github.com/lnls-dig/bpm-sw.git .bpm-sw-libs

    # Configure and Install
    for project in .bpm-sw-libs; do
        cd $project && \
        git submodule update --init --recursive

        # Compile an install dynamic libraries needed by client
        # applications
        for lib in liberrhand libconvc libhutils libdisptable libllio libbpmclient; do
            COMMAND="make \
                ERRHAND_DBG=${ERRHAND_DBG_VAL} \
                ERRHAND_MIN_LEVEL=${ERRHAND_MIN_LEVEL_VAL} \
                ERRHAND_SUBSYS_ON='"${ERRHAND_SUBSYS_ON_VAL}"' \
                BOARD=${BOARD_VAL} $lib && \
                sudo make ${lib}_install"
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
#    git clone --branch=v0.1.2 git://github.com/lnls-dig/bpm-sw-cli.git
    git clone --branch=master git://github.com/lnls-dig/bpm-sw-cli.git

    # Configure and Install
    for project in bpm-sw-cli; do
        cd $project && \
        git submodule update --init --recursive && \
        sudo ./compile.sh ${BPM_SW_CLI_PREFIX} && \
        cd ..

        # Check last command return status
        if [ $? -ne 0 ]; then
            echo "Could not compile/install project $project." >&2
            echo "Try executing the script with root access." >&2
            exit 1
        fi
    done
fi

# Both server and client needs EPICS, but only after BPM-sw is installed
if [ "$ROLE" == "server" ] || [ "$ROLE" == "client" ]; then
    git clone --branch=master git://github.com/lnls-dig/bpm-epics-ioc.git

    # Configure and Install IOC BPM
    for project in bpm-epics-ioc; do
        cd $project && \
        git submodule update --init --recursive && \
        make && \
        make install && \
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

echo "BPM software installation completed"
