#!/usr/bin/env bash

# Exit on error
set -e
# Check for uninitialized variables
set -u

# Our options
BPM_SW_BOARD="afcv3"
BPM_SW_APPS="ebpm"
BPM_SW_WITH_LIBS_LINK="no"
BPM_SW_WITH_EXAMPLES="yes"
BPM_SW_CLI_PREFIX=/usr/local

# BPM client lib flags
ERRHAND_DBG=y
ERRHAND_MIN_LEVEL=DBG_LVL_INFO
ERRHAND_SUBSYS_ON='"(DBG_DEV_MNGR | DBG_DEV_IO | DBG_SM_IO | DBG_LIB_CLIENT | DBG_SM_PR | DBG_SM_CH | DBG_LL_IO | DBG_HAL_UTILS)"'

VALID_ROLES_STR="Valid values are: \"server\", \"client\" or \"gateware\"."
VALID_BOARDS_STR="Valid values are: \"ml605\", \"afcv3\" or \"afcv3_1\""
VALID_AUTOTOOLS_CFG_STR="Valid values are: \"yes\" and \"no\"."
VALID_EPICS_CFG_STR="Valid values are: \"yes\" and \"no\"."
VALID_SYSTEM_DEPS_CFG_STR="Valid values are: \"yes\" and \"no\"."

# Source repo versions
. ./repo-versions.sh

function usage {
    echo "Usage: $0 "
    echo "    -r <role = [server|client|gateware]>"
    echo "    -b <board = [ml605|afcv3|afcv3_1]>"
    echo "    -a <install autotools = [yes|no]>"
    echo "    -e <install EPICS tools = [yes|no]>"
    echo "    -s <install system dependencies = [yes|no]>"
    echo "    -i <install the packages>"
    echo "    -o <download the packages>"
}

# Select if we are deploying in server or client: server or client
ROLE=
# Select board in which we will work. Options are: ml605 or afcv3
BOARD=
# Select if we want autotools or not. Options are: yes or no
AUTOTOOLS_CFG="no"
# Select if we want epics or not. Options are: yes or no
EPICS_CFG="no"
# Select if we want to install system dependencies or not. Options are: yes or no
SYSTEM_DEPS_CFG="no"
# Select if we want to install the packages or not. Options are: yes or no
INSTALL_APP="no"
# Select if we want to download the packages or not. Options are: yes or no
DOWNLOAD_APP="no"

# Get command line options
while getopts ":r:b:a:e:s:io" opt; do
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
        s)
            SYSTEM_DEPS_CFG=$OPTARG
            ;;
        i)
            INSTALL_APP="yes"
            ;;
        o)
            DOWNLOAD_APP="yes"
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

# Check for uninitialized variables
set -u

# Export children variables
export INSTALL_APP
export DOWNLOAD_APP
export BOARD
export BPM_SW_BOARD
export BPM_SW_APPS
export BPM_SW_WITH_LIBS_LINK
export BPM_SW_WITH_EXAMPLES
export BPM_SW_CLI_PREFIX
export ERRHAND_DBG
export ERRHAND_MIN_LEVEL
export ERRHAND_SUBSYS_ON

######################## System Dependencies Installation ######################

if [ "$SYSTEM_DEPS_CFG" == "yes" ]; then
    ./get-system-deps.sh

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install system dependencies." >&2
        exit 1
    fi
fi

############################ Autotools Installation ############################

# Check if we want to install autotools
if [ "$AUTOTOOLS_CFG" == "yes" ]; then
    ./get-autotools.sh

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project autotools." >&2
        exit 1
    fi
fi

############################## EPICS Installation ##############################

# Check if we want to install epics
if [ "$EPICS_CFG" == "yes" ]; then
    ./get-epics.sh

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install project epics." >&2
        exit 1
    fi
fi

########################### BPM-SW Installation ################################

# Both server and client needs these libraries
if [ "$ROLE" == "server" ] || [ "$ROLE" == "client" ]; then
    ./get-bpm-deps.sh

    # Check last command return status
    if [ $? -ne 0 ]; then
        echo "Could not compile/install BPM dependencies." >&2
        exit 1
    fi
fi

# Server
if [ "$ROLE" == "server" ]; then
   ./get-bpm-server.sh

   # Check last command return status
   if [ $? -ne 0 ]; then
       echo "Could not compile/install BPM server." >&2
       exit 1
   fi

   # Also install client application on server

   ./get-bpm-client.sh

   # Check last command return status
   if [ $? -ne 0 ]; then
       echo "Could not compile/install BPM client." >&2
       exit 1
   fi
fi

# Client
if [ "$ROLE" == "client" ]; then
    ./get-bpm-cli-deps.sh

   # Check last command return status
   if [ $? -ne 0 ]; then
       echo "Could not compile/install BPM client dependencies." >&2
       exit 1
   fi

    ./get-bpm-client.sh

   # Check last command return status
   if [ $? -ne 0 ]; then
       echo "Could not compile/install BPM client." >&2
       exit 1
   fi
fi

# Both server and client needs EPICS, but only after BPM-sw is installed
if [ "$ROLE" == "server" ] || [ "$ROLE" == "client" ]; then
    ./get-bpm-epics.sh

   # Check last command return status
   if [ $? -ne 0 ]; then
       echo "Could not compile/install BPM EPICS IOC." >&2
       exit 1
   fi
fi

# Gateware
if [ "$ROLE" == "gateware" ]; then
    ./get-bpm-gateware.sh

   # Check last command return status
   if [ $? -ne 0 ]; then
       echo "Could not compile/install BPM Gatware." >&2
       exit 1
   fi
fi

echo "BPM software installation completed"
