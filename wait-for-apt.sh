#!/bin/bash

while sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1 ; do
  sleep 1
done
