#!/bin/bash

set -e
source environment

#./sign-all.sh

cd packages

rm -rf Packages.bz2 Packages.gz packages.db packages Release Release.gpg Sources Sources.bz2 Sources.gz
mini-dinstall -c ../mini-dinstall.conf --run

echo waiting for mini-dinstall to finish
while (pgrep --full -i mini-dinstall > /dev/null); do
  sleep 1
done

gpg --batch --default-key ${DPKG_GPG_KEYID} --detach-sign -o Release.gpg Release
