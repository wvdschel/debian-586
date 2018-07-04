#!/bin/bash
set -e
source environment

for i in packages/*.dsc packages/*.changes packages/*.buildinfo; do
        echo signing $i
        debsign --re-sign -e="${DPKG_BUILD_MAINTAINER}" -k${DPKG_GPG_KEYID} $i
done
