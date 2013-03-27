#!/bin/bash

PROJECT=$1

pushd ${PROJECT}

hg export -r0:tip -o ${PROJECT}.patch

# Modify patch (Move all files to subdirectory)

sed -i.bak -e "s/\(diff -r [0-9a-f]* -r [0-9a-f]*\) \(.*\)/\1 ${PROJECT}\/\2/g" ${PROJECT}.patch
sed -i.bak -e "s/--- a/\0\/${PROJECT}/g" ${PROJECT}.patch
sed -i.bak -e "s/+++ b/\0\/${PROJECT}/g" ${PROJECT}.patch

popd
