#!/bin/bash

set -e

PKG=$1
VERSION=$2
ORIGDIR=$PWD
source environment
touch failed blacklist
mkdir -p sources logs packages

if ! [ -z "$PKG" ] && ! [ -z "$VERSION" ] ; then
  if egrep -q "^${PKG} ${VERSION}$" blacklist; then
    echo $PKG $VERSION is blacklisted, skipping build.
    exit 0
  fi
  if egrep -q "^${PKG} ${VERSION}$" failed; then
    echo $PKG $VERSION has failed before, skipping build. To retry, remove the line for $PKG $VERSION from ./failed
    exit 0
  fi
 
  LOGFILE="$ORIGDIR/logs/$PKG.log"
  {
    if ! [ -f packages/${PKG}_${VERSION}[+_]*.deb ]; then
      echo no package matching ${PKG} version ${VERSION} found in packages/
      echo fetching sources for $PKG 
      mkdir -p sources/$PKG
      {
        cd sources/$PKG
        apt-get -y source $PKG &>> $LOGFILE
        SOURCEDIR=$(realpath $(find . -mindepth 1 -maxdepth 1 -type d | head -n1))
        ! [ -z $SOURCEDIR ] && {
          cd $SOURCEDIR
          echo installing build dependencies for $PKG
          sudo apt-get -y build-dep $PKG &> $LOGFILE || {
            echo normal build dependency installation failed, trying to install missing packages manually.
            MISSING_PACKAGES=$(dpkg-checkbuilddeps 2>&1 | cut -d: -f4)
            sudo apt-get autoremove -y &>> $LOGFILE
            sudo apt-get install -y ${MISSING_PACKAGES} &>> $LOGFILE
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
    else
      echo $PKG version $VERSION was built already, not rebuilding
    fi
  } || ( echo Failed to build $PKG. Check $LOGFILE for details ; exit 1 )
else
  echo usage: $0 PACKAGE VERSION
fi
