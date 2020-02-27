#!/usr/bin/env bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

# Our options
HALCS_APPS="halcsd"
HALCS_WITH_EXAMPLES="yes"
HALCS_WITH_DRIVER="yes"
HALCS_CLI_PREFIX=/usr/local

# BPM client lib flags
ERRHAND_DBG=y
ERRHAND_MIN_LEVEL=DBG_LVL_WARN
ERRHAND_SUBSYS_ON='"(DBG_DEV_MNGR | DBG_DEV_IO | DBG_SM_IO | DBG_LIB_CLIENT | DBG_SM_PR | DBG_SM_CH | DBG_LL_IO | DBG_HAL_UTILS)"'

VALID_ROLES_STR="Valid values are: \"server\", \"client\" or \"gateware\"."
VALID_BOARDS_STR="Valid values are: \"ml605\", \"afcv3\" or \"afcv3_1\""
VALID_AUTOTOOLS_CFG_STR="Valid values are: \"yes\" and \"no\"."
VALID_EPICS_CFG_STR="Valid values are: \"yes\" and \"no\"."
VALID_EPICS_V4_CFG_STR="Valid values are: \"yes\" and \"no\"."
VALID_SYSTEM_DEPS_CFG_STR="Valid values are: \"yes\" and \"no\"."
VALID_LOCAL_SYSTEM_DEPS_CFG_STR="Valid values are: \"yes\" and \"no\"."
VALID_BPM_CFG_STR="Valid values are: \"yes\" and \"no\"."
VALID_HALCS_WITH_SYSTEM_INTEGRATION_STR="Valid values are: \"yes\" and \"no\"."
VALID_HALCS_INSTALL_MODE_STR="Valid values are: \"source\" and \"rpm\"."
VALID_HALCS_GENERIC_UDEV_STR="Valid values are: \"yes\" and \"no\"."

# Source environment variables
. ./env-vars.sh

# Source repo versions
. ./repo-versions.sh

function usage {
    echo "Usage: $0 "
    echo "    -r <role = [server|client|gateware]>"
    echo "    -b <board = [ml605|afcv3|afcv3_1]>"
    echo "    -a <install autotools = [yes|no]>"
    echo "    -e <install EPICS tools = [yes|no]>"
    echo "    -x <install EPICS V4 tools = [yes|no]>"
    echo "    -s <install system dependencies = [yes|no]>"
    echo "    -l <install local system dependencies = [yes|no]>"
    echo "    -c <install BPM related packages = [yes|no]>"
    echo "    -l <install HALCS system integration scripts = [yes|no]>"
    echo "    -f <install HALCS mode = [source|rpm]>"
    echo "    -p <install HALCS generic UDEV = [yes|no]>"
    echo "    -i <install the packages>"
    echo "    -o <download the packages>"
    echo "    -u <cleanup packages>"
}

# Select if we are deploying in server or client: server or client
ROLE=
# Select board in which we will work. Options are: ml605 or afcv3
BOARD=
# Select if we want autotools or not. Options are: yes or no
AUTOTOOLS_CFG="no"
# Select if we want epics or not. Options are: yes or no
EPICS_CFG="no"
# Select if we want epics V4 or not. Options are: yes or no
EPICS_V4_CFG="no"
# Select if we want to install system dependencies or not. Options are: yes or no
SYSTEM_DEPS_CFG="no"
# Select if we want to install local system dependencies or not. Options are: yes or no
LOCAL_SYSTEM_DEPS_CFG="no"
# Select if we want to install the packages or not. Options are: yes or no
INSTALL_APP="no"
# Select if we want to download the packages or not. Options are: yes or no
DOWNLOAD_APP="no"
# Select if we want to cleanup the packages or not. This only removes intermediate
# files, that are not needed after the build. Options are: yes or no
CLEANUP_APP="no"
# Select if we want to install BPM related stugg or not. Options are: yes or no.
# Default is yes to keep old behavior
BPM_CFG="yes"
# Select if we want HALCS system integration script or not. Options are: yes or no.
# Default is yes to keep old behavior
HALCS_WITH_SYSTEM_INTEGRATION="no"
# Select if we want to install HALCS from source or RPMs. Options are: rpm or source
# Regardless of the options. The driver is always installed from source
HALCS_INSTALL_MODE="source"
# Select if we want to install HALCS generic UDEV or not. Options are: yes or no
HALCS_GENERIC_UDEV="yes"

# Get command line options
while getopts ":r:b:a:e:x:s:z:c:l:f:p:iou" opt; do
    case $opt in
        r)
            ROLE=$OPTARG
            ;;
        b)
            BOARD=$OPTARG
            ;;
        a)
            AUTOTOOLS_CFG=$OPTARG
            ;;
        e)
            EPICS_CFG=$OPTARG
            ;;
        x)
            EPICS_V4_CFG=$OPTARG
            ;;
        s)
            SYSTEM_DEPS_CFG=$OPTARG
            ;;
        z)
            LOCAL_SYSTEM_DEPS_CFG=$OPTARG
            ;;
        c)
            BPM_CFG=$OPTARG
            ;;
        l)
            HALCS_WITH_SYSTEM_INTEGRATION=$OPTARG
            ;;
        f)
            HALCS_INSTALL_MODE=$OPTARG
            ;;
        p)
            HALCS_GENERIC_UDEV=$OPTARG
            ;;
        i)
            INSTALL_APP="yes"
            ;;
        o)
            DOWNLOAD_APP="yes"
            ;;
        u)
            CLEANUP_APP="yes"
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

if [ "$BOARD" != "afcv3" ] && [ "$BOARD" != "afcv3_1" ] && [ "$BOARD" != "ml605" ] && [ "$ROLE" != "gateware" ]; then
    echo "Option \"-b\" has unspported board. "$VALID_BOARDS_STR
    usage
    exit 1
fi

if [ -z "$AUTOTOOLS_CFG" ]; then
    echo "Option \"-a\" unset. "$VALID_AUTOTOOLS_CFG_STR
    usage
    exit 1
fi

if [ "$AUTOTOOLS_CFG" != "yes" ] && [ "$AUTOTOOLS_CFG" != "no" ]; then
    echo "Option \"-a\" has unsupported option. "$VALID_AUTOTOOLS_CFG_STR
    usage
    exit 1
fi

if [ -z "$EPICS_CFG" ]; then
    echo "Option \"-e\" unset. "$VALID_EPICS_CFG_STR
    usage
    exit 1
fi

if [ "$EPICS_CFG" != "yes" ] && [ "$EPICS_CFG" != "no" ]; then
    echo "Option \"-e\" has unsupported option. "$VALID_EPICS_CFG_STR
    usage
    exit 1
fi

if [ -z "$EPICS_V4_CFG" ]; then
    echo "Option \"-x\" unset. "$VALID_EPICS_V4_CFG_STR
    usage
    exit 1
fi

if [ "$EPICS_V4_CFG" != "yes" ] && [ "$EPICS_V4_CFG" != "no" ]; then
    echo "Option \"-x\" has unsupported option. "$VALID_EPICS_V4_CFG_STR
    usage
    exit 1
fi

if [ -z "$SYSTEM_DEPS_CFG" ]; then
    echo "Option \"-s\" unset. "$VALID_SYSTEM_DEPS_CFG_STR
    usage
    exit 1
fi

if [ "$SYSTEM_DEPS_CFG" != "yes" ] && [ "$SYSTEM_DEPS_CFG" != "no" ]; then
    echo "Option \"-s\" has unsupported option. "$VALID_SYSTEM_DEPS_CFG_STR
    usage
    exit 1
fi

if [ -z "$LOCAL_SYSTEM_DEPS_CFG" ]; then
    echo "Option \"-s\" unset. "$VALID_LOCAL_SYSTEM_DEPS_CFG_STR
    usage
    exit 1
fi

if [ "$LOCAL_SYSTEM_DEPS_CFG" != "yes" ] && [ "$LOCAL_SYSTEM_DEPS_CFG" != "no" ]; then
    echo "Option \"-s\" has unsupported option. "$VALID_LOCAL_SYSTEM_DEPS_CFG_STR
    usage
    exit 1
fi

if [ -z "$BPM_CFG" ]; then
    echo "Option \"-a\" unset. "$VALID_BPM_CFG_STR
    usage
    exit 1
fi

if [ "$BPM_CFG" != "yes" ] && [ "$BPM_CFG" != "no" ]; then
    echo "Option \"-a\" has unsupported option. "$VALID_BPM_CFG_STR
    usage
    exit 1
fi

if [ -z "$HALCS_WITH_SYSTEM_INTEGRATION" ]; then
    echo "Option \"-l\" unset. "$VALID_HALCS_WITH_SYSTEM_INTEGRATION_STR
    usage
    exit 1
fi

if [ "$HALCS_WITH_SYSTEM_INTEGRATION" != "yes" ] && [ "$HALCS_WITH_SYSTEM_INTEGRATION" != "no" ]; then
    echo "Option \"-l\" has unsupported option. "$VALID_HALCS_WITH_SYSTEM_INTEGRATION_STR
    usage
    exit 1
fi

if [ "$HALCS_INSTALL_MODE" != "source" ] && [ "$HALCS_INSTALL_MODE" != "rpm" ]; then
    echo "Option \"-f\" has unsupported option. "$VALID_HALCS_INSTALL_MODE_STR
    usage
    exit 1
fi

if [ "$HALCS_GENERIC_UDEV" != "yes" ] && [ "$HALCS_GENERIC_UDEV" != "no" ]; then
    echo "Option \"-p\" has unsupported option. "$VALID_HALCS_GENERIC_UDEV_STR
    usage
    exit 1
fi

# Check for uninitialized variables
set -u

# Export children variables
export INSTALL_APP
export DOWNLOAD_APP
export CLEANUP_APP
export BOARD
export HALCS_APPS
export HALCS_WITH_SYSTEM_INTEGRATION
export HALCS_WITH_EXAMPLES
export HALCS_WITH_DRIVER
export HALCS_CLI_PREFIX
export HALCS_INSTALL_MODE
export HALCS_GENERIC_UDEV
export ERRHAND_DBG
export ERRHAND_MIN_LEVEL
export ERRHAND_SUBSYS_ON

# Ask sudo password only once and
# keep updating sudo timestamp to
# avoid asking again
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || \
    exit; done 2>/dev/null &

############################# MANIFEST  Installation ##########################

# Write MANIFEST file header
rm -f ${MANIFEST}
cat repo-versions.sh | sed -n '1!p' | tee -a ${MANIFEST}

############## System dependencies and EPICS environment Installation #########

EPICS_DEV_RUN_ALL_OPTS=()

# Check if we want to install autotools
if [ "$AUTOTOOLS_CFG" == "yes" ]; then
    EPICS_DEV_RUN_ALL_OPTS+=("-a yes")
else
    EPICS_DEV_RUN_ALL_OPTS+=("-a no")
fi

# Check if we want to install epics
if [ "$EPICS_CFG" == "yes" ]; then
    EPICS_DEV_RUN_ALL_OPTS+=("-e yes")
    # Install synapps, as well
    EPICS_DEV_RUN_ALL_OPTS+=("-n yes")
    # Install new streamDevice
    EPICS_DEV_RUN_ALL_OPTS+=("-t yes")
else
    EPICS_DEV_RUN_ALL_OPTS+=("-e no")
    EPICS_DEV_RUN_ALL_OPTS+=("-n no")
    EPICS_DEV_RUN_ALL_OPTS+=("-t no")
fi

# Check if we want to install epics V4
if [ "$EPICS_V4_CFG" == "yes" ]; then
    EPICS_DEV_RUN_ALL_OPTS+=("-x yes")
else
    EPICS_DEV_RUN_ALL_OPTS+=("-x no")
fi

# Check if we want to install system deps
if [ "$SYSTEM_DEPS_CFG" == "yes" ]; then
    EPICS_DEV_RUN_ALL_OPTS+=("-s yes")
else
    EPICS_DEV_RUN_ALL_OPTS+=("-s no")
fi

# Check if we want to install packages
if [ "$INSTALL_APP" == "yes" ]; then
    EPICS_DEV_RUN_ALL_OPTS+=("-i")
fi
# Check if we want to download packages
if [ "$DOWNLOAD_APP" == "yes" ]; then
    EPICS_DEV_RUN_ALL_OPTS+=("-o")
fi
# Check if we want to download packages
if [ "$CLEANUP_APP" == "yes" ]; then
    EPICS_DEV_RUN_ALL_OPTS+=("-c")
fi

# Do git submodule init/update if not available
if [ -z "$(ls -A ./foreign/epics-dev)" ]; then
    git submodule init && git submodule update
fi

# Change to directory
cd foreign/epics-dev
./run-all.sh ${EPICS_DEV_RUN_ALL_OPTS[*]}
cd ../../

# Check last command return status
if [ $? -ne 0 ]; then
    echo "Could not compile/install project epics." >&2
    exit 1
fi

###################### System Dependencies Installation ########################

if [ "$LOCAL_SYSTEM_DEPS_CFG" == "yes" ]; then
    ./get-local-system-deps.sh

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install local system dependencies." >&2
        exit 1
    fi
fi

########################### BPM-SW Installation ################################

# Both server and client needs these libraries
if [ "$BPM_CFG" == "yes" ]; then
    if [ "$ROLE" == "server" ] || [ "$ROLE" == "client" ]; then
        ./get-bpm-deps.sh

        # Check last command return status
        if [ $? -ne 0 ]; then
            echo "Could not compile/install BPM dependencies." >&2
            exit 1
        fi
    fi

    if [ "$ROLE" == "server" ]; then
        ./get-malamute.sh

        # Check last command return status
        if [ $? -ne 0 ]; then
            echo "Could not compile/install Malamute." >&2
            exit 1
        fi
    fi
fi

# Server
if [ "$BPM_CFG" == "yes" ]; then
    if [ "$ROLE" == "server" ]; then
       ./get-bpm-server.sh

       # Check last command return status
       if [ $? -ne 0 ]; then
           echo "Could not compile/install BPM server." >&2
           exit 1
       fi

       # Don't install client application on server, as we don't need it
       #./get-bpm-client.sh

       # Check last command return status
       if [ $? -ne 0 ]; then
           echo "Could not compile/install BPM client." >&2
           exit 1
       fi
    fi
fi

# HALCS generic UDEV
if [ "$HALCS_GENERIC_UDEV" == "yes" ]; then
    ./get-halcs-generic-udev.sh

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install HALCS generic UDEV." >&2
        exit 1
    fi
fi

# Client
if [ "$BPM_CFG" == "yes" ]; then
    if [ "$ROLE" == "client" ]; then
        ./get-bpm-cli-deps.sh

       # Check last command return status
       if [ $? -ne 0 ]; then
           echo "Could not compile/install BPM client dependencies." >&2
           exit 1
       fi
    fi
fi

# Both server and client needs EPICS, but only after BPM-sw is installed
if [ "$BPM_CFG" == "yes" ]; then
    if [ "$EPICS_CFG" == "yes" ] && ( [ "$ROLE" == "server" ] || [ "$ROLE" == "client" ] ); then
        echo "Installing EPICS"
        ./get-bpm-epics.sh

       # Check last command return status
       if [ $? -ne 0 ]; then
           echo "Could not compile/install BPM EPICS IOC." >&2
           exit 1
       fi
    fi
fi

# Gateware
if [ "$BPM_CFG" == "yes" ]; then
    if [ "$ROLE" == "gateware" ]; then
        ./get-bpm-gateware.sh

       # Check last command return status
       if [ $? -ne 0 ]; then
           echo "Could not compile/install BPM Gatware." >&2
           exit 1
       fi
    fi
fi

echo "BPM software installation completed"
