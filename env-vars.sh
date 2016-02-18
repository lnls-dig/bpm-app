#!/usr/bin/env bash

# Check for uninitialized variables
set -u
# Exit on error
set -e

# Add GLIB pkg-config file (*.pc) to pkg-config path, so
# a possible update on pkg-config works.
GLIB_PKG_CONFIG_PATH=$(find /usr/ -type f -iname "glib-2.0.pc" -print | head -n 1)

# Don't care if PKG_CONFIG_PATH is unbounded here, as we might not have
# this previously set
set +u
export PKG_CONFIG_PATH=${GLIB_PKG_CONFIG_PATH}${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}
set -u
