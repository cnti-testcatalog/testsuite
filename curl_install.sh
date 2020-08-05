#!/bin/bash

if [[ "$SHELL" == *"bash"* ]]; then
    echo "Shell Type: Bash"
    SHELL_PROFILE=~/.bashrc
    SHELL_DOT_DIR=~/.bash.d/
elif [[ "$SHELL" == *"zsh"* ]]; then
    echo "Shell Type: Zsh"
    SHELL_PROFILE=~/.zshrc
    SHELL_DOT_DIR=~/.zsh.d/
else
    SHELL_UNSUPPORTED=true
    echo "Unsupported Shell Type Found: $SHELL"
    echo "Using generic 'path' for setup/cleanup"
fi

if [ "$1" = "cleanup" ]; then 
    if [ -z ${SHELL_UNSUPPORTED+x} ]; then
        rm "$SHELL_DOT_DIR"cnf-conformance
    fi
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
mkdir -p ~/.cnf-conformance
curl -L https://github.com/cncf/cnf-conformance/releases/download/$LATEST_RELEASE/cnf-conformance-$LATEST_RELEASE.tar.gz -o ~/.cnf-conformance/cnf-conformance.tar.gz
tar -C ~/.cnf-conformance -xvf ~/.cnf-conformance/cnf-conformance.tar.gz
rm ~/.cnf-conformance/cnf-conformance.tar.gz

if [ -z ${SHELL_UNSUPPORTED+x} ]; then

    if ! grep -Fxq "for s in $SHELL_DOT_DIR*" $SHELL_PROFILE; then
        echo "for s in $SHELL_DOT_DIR*" >> $SHELL_PROFILE
        echo 'do' >> $SHELL_PROFILE
        echo '   [[ -f "$s" ]] && source $s' >> $SHELL_PROFILE
        echo 'done' >> $SHELL_PROFILE
    fi

    mkdir -p $SHELL_DOT_DIR
    echo 'export PATH=$HOME/.cnf-conformance:$PATH' > ${SHELL_DOT_DIR}cnf-conformance
fi


if [ -z ${SHELL_UNSUPPORTED+x} ]; then

    if (return 0 2>/dev/null); then
        export PATH=$HOME/.cnf-conformance:$PATH
        echo "The cnf-conformance 'path' has been written to ${SHELL_DOT_DIR}cnf-conformance"
        echo "cnf-conformance has been successfully installed to: ~/.cnf-conformance"
    else
        echo "The cnf-conformance 'path' has been written to ${SHELL_DOT_DIR}cnf-conformance"
        echo "cnf-conformance has been successfully installed to: ~/.cnf-conformance"
        echo "To use cnf-conformance please restart you terminal session to load the new 'path'"
        echo "Or you can manually run 'export PATH=\$HOME/.cnf-conformance:\$PATH' in your current session"
    fi
else
    echo "Because an unsupported shell was detected you will need to manually set you path using something like:"
    echo "'export PATH=\$HOME/.cnf-conformance:\$PATH'"
fi

