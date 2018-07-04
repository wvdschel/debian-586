#!/bin/bash

set -e

PKGS=$@
ORIGDIR=$PWD
source environment
mkdir -p sources logs packages
touch finished

for PKG in $PKGS ; do
  LOGFILE="$ORIGDIR/logs/$PKG.log"
  {
    if ! ( egrep -q "^${PKG}$" finished ); then
      echo installing build dependencies for $PKG
      sudo apt-get -y build-dep $PKG &> $LOGFILE
      echo fetching sources for $PKG 
      mkdir -p sources/$PKG
      {
        cd sources/$PKG
        apt-get -y source $PKG &>> $LOGFILE
        SOURCEDIR=$(realpath $(find . -maxdepth 1 -name $PKG-\* -type d | head -n1))
        ! [ -z $SOURCEDIR ] && {
          echo Building sources from $SOURCEDIR
          cd $SOURCEDIR
          dpkg-buildpackage --build-by="${DPKG_BUILD_MAINTAINER}" ${DPKG_BUILDPACKAGE_FLAGS} &>> $LOGFILE 
          cd ..
          mv *.deb *.buildinfo *.dsc *.changes ../../packages/
          cd ../..
        }
      }
      rm -r sources/$PKG
      echo $PKG >> finished
    else
      echo $PKG was built already, not rebuilding
    fi
  } || ( echo Failed to build $PKG. Check $LOGFILE for details ; exit 1 )
done
