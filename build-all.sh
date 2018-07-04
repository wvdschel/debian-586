#!/bin/bash
set -e

PACKAGES=$(apt list | grep / | cut -d/ -f1)
for PKG in $PACKAGES ; do
  ./build-pkg.sh $PKG
done
