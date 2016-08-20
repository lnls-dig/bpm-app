#!/usr/bin/env bash

# Check for uninitialized variables
set -u
# Exit on error
set -e

echo "Fixing system dependencies"

distro=$(./get-os-distro.sh -d)
distro_xsubpp=$(which xsubpp)
epics_xsubpp="/usr/share/perl5/ExtUtils/xsubpp"

case $distro in
    "Ubuntu" | "Debian")
        ;;
    "Fedora" | "RedHat" | "Scientific")
        # EPICS expects xsubpp in a different directory than shipped with fedora (24 at least)
        sudo ln -s ${distro_xsubpp} ${epics_xsubpp}
        ;;
    "SUSE")
        ;;
    *)
        echo "Unsupported distribution: $distro" >&2
        exit 1
        ;;
esac

echo "Fixing system dependencies completed"
