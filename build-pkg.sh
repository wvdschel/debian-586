#!/bin/bash

set -euo pipefail

PKG=$1
VERSION=$2
ORIGDIR=$PWD
source environment
touch failed blacklist
mkdir -p sources logs packages

if ! [ -z "$PKG" ] && ! [ -z "$VERSION" ] ; then
  LOGFILE="$ORIGDIR/logs/$PKG.log"
  echo -n | { # echo command prevents any steps to wait for stdin, since they'll just get EOF.
    echo no package matching ${PKG} version ${VERSION} found in packages/
    echo fetching sources for $PKG 
    mkdir -p sources/$PKG
    {
      cd sources/$PKG
      apt-get -yq source $PKG &>> $LOGFILE
      SOURCEDIR=$(realpath $(find . -mindepth 1 -maxdepth 1 -type d | head -n1))
      ! [ -z $SOURCEDIR ] && {
        cd $SOURCEDIR
        echo installing build dependencies for $PKG
        $ORIGDIR/wait-for-apt.sh # Naive attempt to allow concurrent builders. Not fool-proof
        sudo apt-get build-dep -qy $PKG &> $LOGFILE || {
          echo normal build dependency installation failed, trying to install missing packages manually.
          MISSING_PACKAGES=$(dpkg-checkbuilddeps 2>&1 | cut -d: -f4)
          sudo apt-get autoremove -qy &>> $LOGFILE
          sudo apt-get install -qy ${MISSING_PACKAGES} &>> $LOGFILE
        } || (echo failed to install build dependencies for $PKG ; exit 1)
        echo building from sources in $SOURCEDIR
        dpkg-buildpackage --build-by="${DPKG_BUILD_MAINTAINER}" ${DPKG_BUILDPACKAGE_FLAGS} &>> $LOGFILE 
        cd ..
        echo build artifacts for $PKG: *.deb *.buildinfo *.dsc *.changes
        mv *.deb *.buildinfo *.dsc *.changes ../../packages/
      } || exit 1
      cd ../..
    } || exit 1
    rm -rf sources/$PKG
  } || ( echo Failed to build $PKG. Check $LOGFILE for details ; exit 1 )
  if ! [ -f packages/${PKG}_${VERSION}*.deb ]; then
    echo no package matching ${PKG} version ${VERSION} found in packages/ AFTER building from source. Considering the build to have failed.
    exit 1
  fi
else
  echo usage: $0 PACKAGE VERSION
fi
