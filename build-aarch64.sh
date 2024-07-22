#!/bin/bash

set -eu

for pck in $(<packages.txt); do
  ./build-package.sh -a aarch64 -o output-aarch64  $pck
done