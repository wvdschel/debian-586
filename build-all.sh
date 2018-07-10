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
  local PROGRESS=$(( $PKG_IDX / $PKG_COUNT ))
  local MSG
  local MSG1
  local MSG2
  while read MSG; do
    MSG1="${MSG:0:74}"
    MSG2="${MSG:74:74}"
    echo "[$PKG_IDX/$PKG_COUNT] $PKG: $MSG" >> logs/000-meta-build-all.log
    echo -e "XXX\n${PROGRESS}\n$PKG: ${MSG}\nXXX"
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

  if [ -z "$VERSION" ] ; then
    echo "failed to determine version for $PKG"
  elif ./build-pkg.sh $PKG $VERSION ; then
    echo "finished"
  else
    echo $PKG $VERSION >> failed
    echo "failed"
  fi | whiptailify
done | whiptail --title "Building all Debian packages" --gauge "Warm-up" 6 78 0
