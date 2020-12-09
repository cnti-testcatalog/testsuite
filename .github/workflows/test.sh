#!/bin/bash

if git diff --name-only HEAD master | grep -P '^((?!.md).)*$'; then
    echo 'Run Specs'
else
    echo 'Skip Specs'
fi
