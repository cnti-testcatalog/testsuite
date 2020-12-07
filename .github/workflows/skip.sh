#!/bin/bash

if git branch | grep '^* master$'; then
   if ! git diff --name-only HEAD HEAD~1 | grep -q -P '^((?!.md).)*$'; then
       echo 'true'
   else
       echo 'false'
   fi
else
   if ! git diff --name-only HEAD origin/master | grep -q -P '^((?!.md).)*$'; then
       echo 'true'
   else
       echo 'false'
   fi
fi
