#!/usr/bin/env bash

#    Allows to easily download and install scripts from this repository.
#    Copyright (C) 2017 Dmitry Berezovsky
#
#    The MIT License (MIT)
#    Permission is hereby granted, free of charge, to any person obtaining
#    a copy of this software and associated documentation files
#    (the "Software"), to deal in the Software without restriction,
#    including without limitation the rights to use, copy, modify, merge,
#    publish, distribute, sublicense, and/or sell copies of the Software,
#    and to permit persons to whom the Software is furnished to do so,
#    subject to the following conditions:
#
#    The above copyright notice and this permission notice shall be
#    included in all copies or substantial portions of the Software.
#
#    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Fail on error
set -e

# ======= PARAMETERS ==============
ARG_HELP=0
ARG_TAG="master"
ARG_BASE_URL="https://raw.githubusercontent.com/Logicify/unix-utils"
ARG_TARGET="/usr/bin"
ARG_PKG="full"

# ========== END ==================

function print_help() {
    echo ""
    echo "Usage: install-toolchain [-v,--version] [-u,--url] [-d,--dest] [package]"
    echo ""
    echo "-v, --version     Version of the toolchain which needs to be installed (tag or branch)"
    echo "-u, --url         Base URL of the repository containing toolchain. Default: https://raw.githubusercontent.com/Logicify/unix-utils"
    echo "-d, --dest        Target directory for installation"
    echo ""
    echo "Positional Arguments"
    echo "package           package to be installed. Default: full"
    echo ""
    echo "
MIT License"
    echo "Copyright (C) 2017 Dmitry Berezovsky (https://github.com/Logicify/unix-utils)"
}

function parse_arguments() {
    while [[ $# -gt 1 ]]
    do
        key="$1"
        echo "K: $key"
        case "$key" in
            -v|--version)
            ARG_TAG="$2"
            shift
            shift # past argument
            ;;
            -u|--url)
            ARG_BASE_URL="$2"
            shift
            shift # past argument
            ;;
            -h|--help)
            ARG_HELP=1
            break;
            ;;
            -d|--dest)
            ARG_TARGET="$2"
            shift
            shift # past argument
            ;;
            *)
                break # No more named arguments left
            ;;
        esac
    done

    if [ -z "$1" ]; then
        echo "Using default package: $ARG_PKG"
    else
       ARG_PKG="$1"
    fi
}

function install_script() {
    path="$1"
    script_url="$ARG_BASE_URL/$ARG_TAG/$path"
    target_file_name=`basename "$path" | sed s/.sh//`
    target_full_path="$ARG_TARGET/$target_file_name"
    echo " * Installing $path into $target_full_path"
    curl -LNSs -o "$target_full_path" "$script_url"
    chmod a+x "$target_full_path"
}

# Parse arguments and show help if invocation is wrong
parse_arguments $@

# Show help message if -h flag specified
if [ ${ARG_HELP} -gt 0 ]; then
    print_help
fi

mkdir -p "$ARG_TARGET"

case $ARG_PKG in
    full|all)
    echo "AWS tools:"
    install_script "aws/mount-ebs.sh"
    install_script "aws/aws-set-hostname.sh"
    echo "Docker:"
    install_script "docker/copy-docker-image.sh"
    install_script "docker/dive.sh"
    ;;
    *)
        echo "Unknown package: $ARG_PKG"
        print_help
        exit 1
    ;;
esac