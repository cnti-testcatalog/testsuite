#!/bin/bash

if git diff --name-only HEAD main | grep -P '^((?!.md).)*$'; then
    echo 'Run Specs'
else
    echo 'Skip Specs'
fi
