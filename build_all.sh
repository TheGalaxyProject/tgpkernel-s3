#!/bin/bash
# Build TGPKernel
git checkout tw444
./build.sh 2
./build.sh 0

# Build TGPKernel Lite
git checkout tw444-lite
./build.sh 2
./build.sh 0

