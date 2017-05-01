#!/bin/bash

# Working setup to cross-compile Windows binaries for Slimcoin hosted on a
# Vagrant Ubuntu 16.04 VM using non-Canonical ppas for MXE and Qt5.7:
# deb http://pkg.mxe.cc/repos/apt/debian wheezy main

# Doesn't seem to pass the QT directives through, though. Tough.

# Basic path bindings
PATH=/usr/lib/mxe/usr/bin:$PATH
MXE_PATH=/usr/lib/mxe
MXE_INCLUDE_PATH=/usr/lib/mxe/usr/i686-w64-mingw32.static/include
MXE_LIB_PATH=/usr/lib/mxe/usr/i686-w64-mingw32.static/lib
# BDB_INCLUDE_PATH=/mnt/slm/db4/include
# BDB_LIB_PATH=/mnt/slm/db4/lib

# Belt and braces
CXXFLAGS="-std=gnu++11 -march=i686"
LDFLAGS="-march=i686"
target="i686-w64-mingw32.static"

# Particularise for cross-compiling
export BOOST_LIB_SUFFIX=-mt
export BOOST_THREAD_LIB_SUFFIX=_win32-mt
export BOOST_INCLUDE_PATH=${MXE_INCLUDE_PATH}/boost
export BOOST_LIB_PATH=${MXE_LIB_PATH}
export OPENSSL_INCLUDE_PATH=${MXE_INCLUDE_PATH}/openssl
export OPENSSL_LIB_PATH=${MXE_LIB_PATH}
# export BDB_INCLUDE_PATH=${BDB_INCLUDE_PATH}
# export BDB_LIB_PATH=${BDB_LIB_PATH}
export MINIUPNPC_INCLUDE_PATH=${MXE_INCLUDE_PATH}
export MINIUPNPC_LIB_PATH=${MXE_LIB_PATH}
export QMAKE_LRELEASE=${MXE_PATH}/usr/${target}/qt5/bin/lrelease

cat >> slimcoin-qt.pro.patch <<EOT
--- a/slimcoin-qt.pro
+++ b/slimcoin-qt.pro
@@ -697,6 +697,7 @@ windows:QMAKE_LFLAGS *= -Wl,--dynamicbase -Wl,--nxcompat
 # on Windows: enable GCC large address aware linker flag
 # hack: when compiling 64-bit, pass 64BIT=1 to qmake to avoid incompatible large-address flag
 windows:!contains(64BIT, 1) QMAKE_LFLAGS *= -Wl,--large-address-aware
+windows:contains(MXE, 1) LIBS += -lpthread
 
 macx:{
     QMAKE_RPATHDIR += @executable_path/../Frameworks
EOT
patch -p 1 < slimcoin-qt.pro.patch

# Call qmake to create Makefile.[Release|Debug]
${target}-qmake-qt5 \
    MXE=1 \
    USE_O3=1 \
    USE_QRCODE=1 \
    FIRST_CLASS_MESSAGING=1 \
    RELEASE=1 \
    USE_UPNPC=1 \
    BOOST_LIB_SUFFIX=${BOOST_LIB_SUFFIX} \
    BOOST_THREAD_LIB_SUFFIX=${BOOST_THREAD_LIB_SUFFIX} \
    BOOST_INCLUDE_PATH=${BOOST_INCLUDE_PATH} \
    BOOST_LIB_PATH=${BOOST_LIB_PATH} \
    OPENSSL_INCLUDE_PATH=${OPENSSL_INCLUDE_PATH} \
    OPENSSL_LIB_PATH=${OPENSSL_LIB_PATH} \
    MINIUPNPC_INCLUDE_PATH=${MINIUPNPC_INCLUDE_PATH} \
    MINIUPNPC_LIB_PATH=${MINIUPNPC_LIB_PATH} \
    QMAKE_LRELEASE=${QMAKE_LRELEASE} slimcoin-qt.pro
    # BDB_INCLUDE_PATH=${BDB_INCLUDE_PATH} \
    # BDB_LIB_PATH=${BDB_LIB_PATH} \

# Go for it. If successful, Windows binary will be written out to ./release/slimcoin-qt.exe
make -f Makefile.Release CXXFLAGS="-DQT_GUI -DQT_NO_PRINTER -std=gnu++11 -march=i686" LDFLAGS="-march=i686"