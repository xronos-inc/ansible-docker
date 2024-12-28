#!/bin/bash

set -e

export CONTAINER_USER=${CONTAINER_USER:-$(whoami)}

# if ~/.ssh/host-agent.sock exists, use this as the SSH auth sock for forwarding from the host
if [ -e ${HOME}/.ssh/host-agent.sock ]; then
    echo found host SSH agent socket ${HOME}/.ssh/host-agent.sock
    sudo socat UNIX-LISTEN:/home/${CONTAINER_USER}/.ssh/container-agent.sock,fork,user=${CONTAINER_USER},group=${CONTAINER_USER},mode=700 \
          UNIX-CONNECT:/home/${CONTAINER_USER}/.ssh/host-agent.sock &
    export SSH_AUTH_SOCK=/home/${CONTAINER_USER}/.ssh/container-agent.sock
fi

# enable the python virtual environment
source /home/${CONTAINER_USER}/.venv/bin/activate

