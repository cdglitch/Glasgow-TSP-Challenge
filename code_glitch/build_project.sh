#!/bin/bash
for file in zephyrus_cmod_*.pas; do ./build.sh "$file"; done
./build.sh zephyrus_client.pas
cp *cmod*.so data/cmod -v
