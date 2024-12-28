#!/bin/bash

# SPDX-FileCopyrightText: (c) 2024 Xronos Inc.
# SPDX-License-Identifier: BSD-3-Clause

# Download source files and license notifications for third-party
# packages installed by apt or pip. Sources and notifications are
# written to the working directory.
#
# This script may be run as a non-privelaged user.

set -e

function usage(){
    echo "third-party-package.sh [--dpkg <file>] [--pip <file>] [--output-dir <output_dir>]"
    echo ""
    echo "Download source files and license notifications for third-party packages."
    echo ""
    echo "   --dpkg <file>        download sources for the packages listed in <file>"
    echo "                           requires the package dpkg-dev is installed"
    echo "   --pip <file>         generate license file from a pip requirements.txt"
    echo "                           requires the python3 package venv is installed"
    echo "   --output <dir>       write output to this directory."
    echo "                           if not specified, outputs to current working directory"
    echo ""
    echo "   --help               print this message and exit"
}

# download sources for all required debian packages
function dpkg_requirements() {
    if [ -z ${1} ]; then echo error: no dpkg requirements file provided; exit 11; fi
    if [ ! -f ${1} ]; then echo error: dpkg requirements file ${1} not found; exit 12; fi
    local requirements_file=${1}
    shift
    if [ -z ${1} ]; then echo error: no output directory specified for dpkg source; exit 13; fi
    local output_dir=${1}/dpkg-source
    shift

    if ! dpkg -l | grep -qw dpkg-dev; then
        echo error: package dpkg-dev is required to downoad source
        exit 14
    fi

    echo downloading debian sources from ${requirements_file} to ${output_dir}
    mkdir -p ${output_dir}
    mapfile -t packages < ${requirements_file}
    pushd ${output_dir} >/dev/null
    for pkg in "${packages[@]}"; do
        echo downloading source for debian package ${pkg} to ${output_dir}
        apt-get source -qq ${pkg}
        # remove archives after decompression
        find . -maxdepth 1 -type f -name "${pkg%%=*}*.*" -exec rm -f {} +
    done
    popd >/dev/null
}

# download sources for all required python packages
function pip_requirements() {
    if [ -z ${1} ]; then echo error: no pip requirements file provided; exit 21; fi
    if [ ! -f ${1} ]; then echo error: pip requirements file ${1} not found; exit 22; fi
    local requirements_file=${1}
    shift
    if [ -z ${1} ]; then echo error: no output directory specified for pip license file; exit 23; fi
    local output_dir=${1}
    shift

    if ! pip-licenses --version >/dev/null; then
        echo error: python package pip-licenses is required to generate pip license file
        exit 25
    fi

    echo generating pip licenses from ${requirements_file} to ${output_dir}/pip-licenses.json
    # 1. read requirements file
    # 2. omit empty lines
    # 3. strip anything startin from and including =
    # 4. replace newlines with spaces
    # 5. cleanup whitespace
    local packages=$(
        grep -v '^\s*#' ${requirements_file} \
        | grep -v '^\s*$' \
        | sed 's/=.*//' \
        | tr '\n' ' ' \
        | xargs)
    pip-licenses \
        --with-authors \
        --with-urls \
        --with-maintainers \
        --with-license-file \
        --format=json \
        --output-file=${output_dir}/pip-licenses.json \
        --ignore-packages pip-licenses pip setuptools wheel distribute \
        --packages ${packages}
}

# parse arguments
POSITIONAL_ARGS=()
ARG_DPKG_REQ_FILE=
ARG_PIP_REQ_FILE=
ARG_OUTPUT_DIR=${PWD}
while [[ $# -gt 0 ]]; do
    case ${1} in
        -d|--dpkg)
            shift
            if [ -z "${1}" ]; then
                echo "error: --dpkg requires one argument; none provided."
                exit 1
            fi
            ARG_DPKG_REQ_FILE=${1}
            shift
            ;;
        -p|--pip)
            shift
            if [ -z "${1}" ]; then
                echo "error: --pip requires one argument; none provided."
                exit 2
            fi
            ARG_PIP_REQ_FILE=${1}
            shift
            ;;
        -o|--output)
            shift
            if [ -z "${1}" ]; then
                echo "error: --output requires one argument; none provided."
                exit 3
            fi
            ARG_OUTPUT_DIR=${1}
            shift
            ;;
        -h|--help)
            shift
            usage
            exit 0
            ;;
        -*|--*)
            echo "error: unknown argument ${1}"
            usage
            exit 4
            ;;
        *)
            POSITIONAL_ARGS+=("${1}") # save positional arg
            shift # past argument
            ;;
    esac
done
set -- "${POSITIONAL_ARGS[@]}" # restore positional arguments

if [ ! -z ${ARG_DPKG_REQ_FILE} ]; then
   dpkg_requirements ${ARG_DPKG_REQ_FILE} ${ARG_OUTPUT_DIR}
fi

if [ ! -z ${ARG_PIP_REQ_FILE} ]; then
    pip_requirements ${ARG_PIP_REQ_FILE} ${ARG_OUTPUT_DIR}
fi
