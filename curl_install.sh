#!/bin/bash

if [ "$1" = "cleanup" ]; then 
   rm ~/.bash.d/cnf-conformance
   rm -rf ~/.cnf-conformance
   exit 0
fi

get_latest_release() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
        grep '"tag_name":' |                                            # Get tag line
        sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

# Install CNF-Conformance
LATEST_RELEASE=$(get_latest_release cncf/cnf-conformance)
mkdir ~/.cnf-conformance
curl -L https://github.com/cncf/cnf-conformance/releases/download/$LATEST_RELEASE/cnf-conformance.tar.gz -o ~/.cnf-conformance/cnf-conformance.tar.gz
tar -C ~/.cnf-conformance -xvf ~/.cnf-conformance/cnf-conformance.tar.gz
rm ~/.cnf-conformance/cnf-conformance.tar.gz


mkdir -p ~/.bash.d
echo 'export PATH=$HOME/.cnf-conformance:$PATH' > ~/.bash.d/cnf-conformance

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export PATH=$HOME/.cnf-conformance:$PATH
else
    echo 'The cnf-conformance Path has been written to ~/.bash.d/cnf-conformance'
    echo 'To use cnf-conformance please restart you terminal session to load the new Path'
    echo "Or you can manually run 'export PATH=\$HOME/.cnf-conformance:\$PATH' in your current session"
fi



