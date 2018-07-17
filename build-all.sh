#!/bin/bash
set -euo pipefail
PKG_LIST=$(apt list 2> /dev/null | grep /)

PACKAGES=$(cat <<<$PKG_LIST | grep / | cut -d/ -f1)
PKG_COUNT=$(echo $PACKAGES | wc -w)
PKG_IDX=0
PKG=
VERSION=

SKIP=0
if [[ $# -gt 0 ]]; then
  SKIP=$1
  echo skipping $SKIP packages.
fi

function whiptailify() {
  local PROGRESS=$(( 100 * $PKG_IDX / $PKG_COUNT ))
  local MSG
  while read MSG; do
    echo "$(date) [$PKG_IDX/$PKG_COUNT] $PKG: $MSG" | tee -a logs/000-meta-build-all.log
  done
}

# A tainted sources dir WILL break builds
rm -rf sources

for PKG in $PACKAGES ; do
  PKG_IDX=$(( $PKG_IDX + 1 ))
  if [[ $PKG_IDX -le $SKIP ]] ; then 
    continue
  fi
  
  VERSION=$(cat <<<$PKG_LIST | grep $PKG/ | cut -d' ' -f2 | cut -d'+' -f1 | head -n1)
  VERSION=${VERSION#*:}
  VERSION="${VERSION%%[^0-9.\-]*}"

  if [ -z "$VERSION" ] ; then
    echo "failed to determine version for $PKG"
  elif egrep -q "^${PKG} ${VERSION}$" blacklist; then
    echo $PKG $VERSION is blacklisted, skipping build.
  elif egrep -q "^${PKG} ${VERSION}$" failed; then
    echo $PKG $VERSION has failed before, skipping build. To retry, remove the line for $PKG $VERSION from ./failed
  elif [ -f packages/${PKG}_${VERSION}*.deb ]; then
    #echo $PKG version $VERSION was built already, not rebuilding
    continue
  elif ./build-pkg.sh $PKG $VERSION ; then
    echo "finished"
  else
    echo $PKG $VERSION >> failed
    echo "failed"
  fi 2>&1 | whiptailify
done
