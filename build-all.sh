#!/bin/bash
set -e

PACKAGES=$(apt list | grep / | cut -d/ -f1)
PKG_COUNT=$(echo $PACKAGES | wc -w)
PKG_IDX=0
for PKG in $PACKAGES ; do
  ./build-pkg.sh $PKG
  PKG_IDX=$(( $PKG_IDX + 1 ))
  echo "[$PKG_IDX/$PKG_COUNT] $PKG finished"
done
