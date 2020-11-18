#!/bin/bash
if ! git diff --name-only HEAD origin/master | grep -q -P '^((?!.md).)*$'; then
    echo 'true'
else
    echo 'false'
fi
