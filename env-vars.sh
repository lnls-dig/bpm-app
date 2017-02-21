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

# Depending on OS we need to change ADCore paths this differently
distro=$(./get-os-distro.sh -d)
rev=$(./get-os-distro.sh -r)

HDF5_BASE=/lib64
HDF5_LIB=/lib64
HDF5_INCLUDE=/usr/include
SZIP_BASE=/usr/lib64
SZIP_LIB=/usr/lib64
SZIP_INCLUDE=/usr/include
GRAPHICS_MAGICK_BASE=/usr/lib64
GRAPHICS_MAGICK_LIB=/usr/lib64
GRAPHICS_MAGICK_INCLUDE=/usr/include/ImageMagick/magick

case $distro in
    "Ubuntu" | "Debian")
        if [ "$rev" \< "14.04" ] || [ "$rev" == "14.04" ]; then
            HDF5_BASE=/usr/lib/x86_64-linux-gnu
            HDF5_LIB=/usr/lib/x86_64-linux-gnu
            HDF5_INCLUDE=/usr/include
        elif [ "$rev" == "16.04" ]; then
            HDF5_BASE=/usr/lib/x86_64-linux-gnu/hdf5/serial
            HDF5_LIB=/usr/lib/x86_64-linux-gnu/hdf5/serial
            HDF5_INCLUDE=/usr/include/hdf5/serial
        else
            HDF5_BASE=/usr/lib/x86_64-linux-gnu
            HDF5_LIB=/usr/lib/x86_64-linux-gnu
            HDF5_INCLUDE=/usr/include
        fi

        SZIP_BASE=/usr/lib
        SZIP_LIB=/usr/lib
        SZIP_INCLUDE=/usr/include
        GRAPHICS_MAGICK_BASE=/usr/lib/x86_64-linux-gnu
        GRAPHICS_MAGICK_LIB=/usr/lib/x86_64-linux-gnu
        GRAPHICS_MAGICK_INCLUDE=/usr/include/ImageMagick/magick
        ;;
    "Fedora" | "RedHat" | "Scientific")
        HDF5_BASE=/lib64
        HDF5_LIB=/lib64
        HDF5_INCLUDE=/usr/include
        SZIP_BASE=/usr/lib64
        SZIP_LIB=/usr/lib64
        SZIP_INCLUDE=/usr/include
        GRAPHICS_MAGICK_BASE=/usr/lib64
        GRAPHICS_MAGICK_LIB=/usr/lib64
        GRAPHICS_MAGICK_INCLUDE=/usr/include/ImageMagick/magick
        ;;
    "SUSE")
        HDF5_BASE=/lib64
        HDF5_LIB=/lib64
        HDF5_INCLUDE=/usr/include
        SZIP_BASE=/usr/lib64
        SZIP_LIB=/usr/lib64
        SZIP_INCLUDE=/usr/include
        GRAPHICS_MAGICK_BASE=/usr/lib64
        GRAPHICS_MAGICK_LIB=/usr/lib64
        GRAPHICS_MAGICK_INCLUDE=/usr/include/ImageMagick/magick
        ;;
    *)
        echo "Unsupported distribution: $distro" >&2
        exit 1
        ;;
esac

