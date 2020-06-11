#!/bin/bash
if [ -f /home/pod_status ]; then
    echo "State found, exiting"
    exit 1
else
    touch /home/pod_status
    sleep infinity
fi

