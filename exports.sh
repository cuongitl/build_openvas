#
# This file should be sourced 
#
BUILD_OPENVAS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export INSTALL_PREFIX=/usr/local
export PATH=$PATH:$INSTALL_PREFIX/sbin

export SOURCE_DIR=$BUILD_OPENVAS_DIR/working/source
export INSTALL_DIR=$BUILD_OPENVAS_DIR/working/install
export BUILD_DIR=$BUILD_OPENVAS_DIR/working/build

export GVM_LIBS_VERSION=22.34.1
export GVMD_VERSION=26.13.0
export PG_GVM_VERSION=22.6.12
export GSA_VERSION=26.8.0
export GSAD_VERSION=24.12.2
export OPENVAS_SCANNER_VERSION=23.36.0
export OSPD_OPENVAS_VERSION=22.10.0
export OPENVAS_DAEMON=23.36.0
