#!/bin/bash

if git status | grep -q -P -i 'v[0-9]\.[0-9]'; then
   echo 'false'
elif git branch | grep -q '^*.*main.*$'; then
   if ! git diff --name-only HEAD HEAD~1 | grep -q -P '^((?!.md).)*$'; then
       echo 'true'
   else
       echo 'false'
   fi
else
   if ! git diff --name-only HEAD origin/main | grep -q -P '^((?!.md).)*$'; then
       echo 'true'
   else
       echo 'false'
   fi
fi
