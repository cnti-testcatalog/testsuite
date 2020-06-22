#!/bin/bash
echo "ARGS: $@"
echo $(echo $@ | sed 's/^/"/' | sed 's/$/"/')

# POC Dynamic argument passing.
#################test="echo test | sed 's/^/\"/' | sed 's/$/\"/'"
# kdgh="echo spec -v | sed 's/^/\"/' | sed 's/$/\"/'"
# alias crystal2='$(eval $kdgh)'

# args="echo spec -v | sed 's/^/\"/' | sed 's/$/\"/'"
# alias crystal2='crystal $(eval $args)'
# alias crystal2="crystal $(pwd)/tools/ephemeral_env/ephemeral_env.cr command $(eval $args)"

