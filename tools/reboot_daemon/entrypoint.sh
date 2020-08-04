#!/bin/bash

until [ -f /tmp/reboot ]
do
    sleep 1
    echo 'waitting'
done

echo b > /sysrq

