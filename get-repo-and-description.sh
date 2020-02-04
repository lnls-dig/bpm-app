#!/usr/bin/env bash

# Check for uninitialized variables
set -u
# Exit on error
set -e

function usage() {
    echo "Usage: $0 [-b <branch>] [-r <repository URL>] [-d <destination folder>]"
    echo "    [-m <manifest file>]"
}

#######################################
# All of our Makefile options
#######################################

BRANCH=
REPOURL=
DESTINATION=
MANIFEST=

# Get command line options
while getopts ":b:r:d:m:" opt; do
    case $opt in
        b)
            BRANCH=$OPTARG
            ;;
        r)
            REPOURL=$OPTARG
            ;;
        d)
            DESTINATION=$OPTARG
            ;;
        m)
            MANIFEST=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            exit 1
            ;;
    esac
done

if [ -z "$BRANCH"  ]; then
    echo "\"branch\" variable unset."
    usage
    exit 1
fi

if [ -z "$REPOURL"  ]; then
    echo "\"repository URL\" variable unset."
    usage
    exit 1
fi

if [ -z "$DESTINATION"  ]; then
    echo "\"destination folder\" variable unset."
    usage
    exit 1
fi

if [ -z "$MANIFEST"  ]; then
    echo "\"manifest file\" variable unset."
    usage
    exit 1
fi

# Execute command
git clone --recursive --branch=${BRANCH} ${REPOURL} ${DESTINATION}

# Enter in the destination and get some git information
echo "Getting Git metainfo for repository ${DESTINATION}"
cd ${DESTINATION}

NAME=${DESTINATION}
URL=$(git config --get remote.origin.url)
COMMIT=$(git describe --dirty --always --abbrev=10)
# It's ok to accept errros here
set +e
AUTHOR=$(git config --get user.name)
EMAIL=$(git config --get user.email)
set -e

cd ..

echo -e "\n${NAME} Versioning Info\n" | tee -a ${MANIFEST}
echo "url=${URL}" | tee -a ${MANIFEST}
echo "commit=${COMMIT}" | tee -a ${MANIFEST}
echo "author=${AUTHOR}" | tee -a ${MANIFEST}
echo "email=${EMAIL}" | tee -a ${MANIFEST}
