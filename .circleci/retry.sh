#!/bin/bash

echo $1

if ! [[ $1 -eq 0 ]]; then
   echo "exit code: $1"
   TIME=0
   EXIT=1
   until [[ $EXIT -eq 0 ]]; do 
       gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 'EB4C 1BFD 4F04 2F6D DDCC EC91 7721 F63B D38B 4796'; \
       # EXIT=1
       EXIT=$?
       TIME=$(($TIME + 1))
       sleep 1
       if [[ $TIME -eq 10 ]]; then
           exit 1
       fi
   done
fi
