#!/usr/bin/env bash

# Check for uninitialized variables
set -u
# Exit on error
set -e

# Add GLIB pkg-config file (*.pc) to pkg-config path, so
# a possible update on pkg-config works.
GLIB_PKG_CONFIG_PATH=/usr/lib64/pkgconfig
SHARE_PKG_CONFIG_PATH=/usr/share/pkgconfig
MORE_PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

# Don't care if PKG_CONFIG_PATH is unbounded here, as we might not have
# this previously set
set +u
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:${GLIB_PKG_CONFIG_PATH}
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:${SHARE_PKG_CONFIG_PATH}
export PKG_CONFIG_PATH=${PKG_CONFIG_PATH}:${MORE_PKG_CONFIG_PATH}
set -u

# Manifest filename
MANIFEST=MANIFEST
