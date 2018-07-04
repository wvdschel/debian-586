#!/bin/bash

set -e

PKGS=$@
ORIGDIR=$PWD
source environment
mkdir -p sources logs packages

for PKG in ${PKGS}; do
  if egrep -q "^${PKG}$" blacklist; then
    echo $PKG is blacklisted, skipping build.
    continue
  fi
  LOGFILE="$ORIGDIR/logs/$PKG.log"
  {
    VERSION=$(apt list $PKG 2> /dev/null | grep $PKG/ | cut -d' ' -f2 | cut -d'+' -f1 | head -n1)
    VERSION=${VERSION#*:}
    if [ -z "$VERSION" ] ; then
      echo failed to determine version for $PKG
      exit 1
    fi
    if ! [ -f packages/${PKG}_${VERSION}[+_]*.deb ]; then
      echo no package matching ${PKG} version ${VERSION} found in packages/
      echo installing build dependencies for $PKG
      sudo apt-get -y build-dep $PKG &> $LOGFILE
      echo fetching sources for $PKG 
      mkdir -p sources/$PKG
      {
        cd sources/$PKG
        apt-get -y source $PKG &>> $LOGFILE
        SOURCEDIR=$(realpath $(find . -mindepth 1 -maxdepth 1 -type d | head -n1))
        ! [ -z $SOURCEDIR ] && {
          echo Building sources from $SOURCEDIR
          cd $SOURCEDIR
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
done
