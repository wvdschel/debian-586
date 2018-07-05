#!/bin/bash
set -e
PKG_LIST=$(apt list 2> /dev/null | grep /)

PACKAGES=$(cat <<<$PKG_LIST | grep / | cut -d/ -f1)
PKG_COUNT=$(echo $PACKAGES | wc -w)
PKG_IDX=0
for PKG in $PACKAGES ; do
  VERSION=$(cat <<<$PKG_LIST | grep $PKG/ | cut -d' ' -f2 | cut -d'+' -f1 | head -n1)
  VERSION=${VERSION#*:}
  PKG_IDX=$(( $PKG_IDX + 1 ))

  if [ -z "$VERSION" ] ; then
    echo "[$PKG_IDX/$PKG_COUNT] failed to determine version for $PKG"
  elif ./build-pkg.sh $PKG $VERSION ; then
    echo "[$PKG_IDX/$PKG_COUNT] $PKG finished"
  else
    echo $PKG >> failed
    echo "[$PKG_IDX/$PKG_COUNT] $PKG failed"
  fi
done
