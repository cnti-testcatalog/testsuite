#!/bin/bash
set -o errexit

if [[ "$SHELL" == *"bash"* ]]; then
    SHELL_PROFILE=~/.bashrc
    SHELL_DOT_DIR=~/.bash.d/
elif [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_PROFILE=~/.zshrc
    SHELL_DOT_DIR=~/.zsh.d/
else
    SHELL_UNSUPPORTED=true
fi

if [ "$1" = "cleanup" ]; then 
    if [ -z ${SHELL_UNSUPPORTED+x} ]; then
        rm "$SHELL_DOT_DIR"cnf-testsuite
    fi
    rm -rf ~/.cnf-testsuite
    exit 0
fi


get_latest_release() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
        grep '"tag_name":' |                                            # Get tag line
        sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

# Install CNF-TestSuite
LATEST_RELEASE=$(get_latest_release lfn-cnti/testsuite)
mkdir -p ~/.cnf-testsuite
curl --silent -L https://github.com/lfn-cnti/testsuite/releases/download/$LATEST_RELEASE/cnf-testsuite-$LATEST_RELEASE.tar.gz -o ~/.cnf-testsuite/cnf-testsuite.tar.gz
tar -C ~/.cnf-testsuite -xf ~/.cnf-testsuite/cnf-testsuite.tar.gz
chmod a+x ~/.cnf-testsuite/cnf-testsuite
rm ~/.cnf-testsuite/cnf-testsuite.tar.gz

if [ -z ${SHELL_UNSUPPORTED+x} ]; then

    if ! grep -Fxq "for s in $SHELL_DOT_DIR*" $SHELL_PROFILE; then
        echo "for s in $SHELL_DOT_DIR*" >> $SHELL_PROFILE
        echo 'do' >> $SHELL_PROFILE
        echo '   [[ -f "$s" ]] && source $s' >> $SHELL_PROFILE
        echo 'done' >> $SHELL_PROFILE
    fi

    mkdir -p $SHELL_DOT_DIR
    echo 'export PATH=$HOME/.cnf-testsuite:$PATH' > ${SHELL_DOT_DIR}cnf-testsuite
fi


if [ -z ${SHELL_UNSUPPORTED+x} ]; then

    if (return 0 2>/dev/null); then
        export PATH=$HOME/.cnf-testsuite:$PATH
        echo "cnf-testsuite has been successfully installed to ~/.cnf-testsuite and added to your PATH"
    else
        echo "cnf-testsuite has been successfully installed to: ~/.cnf-testsuite"
        echo "To use the cnf-testsuite please restart you terminal session to load the new PATH"
        echo "Or you can manually run 'export PATH=\$HOME/.cnf-testsuite:\$PATH' in your current session"
    fi
else
    echo "Because an unsupported shell was detected you will need to manually set you PATH, eg.:"
    echo "'export PATH=\$HOME/.cnf-testsuite:\$PATH'"
fi

