#!/bin/bash

set -eu

for pck in $(<bootstrap-packages.txt); do
  ./build-package.sh -a aarch64 -o output  $pck
done