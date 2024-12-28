# SPDX-FileCopyrightText: © 2024 Xronos Inc.
# SPDX-License-Identifier: BSD-3-Clause

##################
## global arguments
##################

# image from which all other stages derive
ARG BASEIMAGE=ubuntu:jammy-20240911.1

##################
## dependencies stage
##################
# this stage installs all system dependencies as the root user
FROM ${BASEIMAGE} AS base
USER root
SHELL ["/bin/bash", "-c"]

# Preconfigure debconf for non-interactive installation - otherwise complains about terminal
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=localhost:0.0
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN echo -e '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d

# apt dependencies
RUN apt-get update -q
RUN apt-get install --no-install-recommends -y -q apt-utils=2.4.13 2>&1 \
	| grep -v "debconf: delaying package configuration"
# tools used by ansible
RUN apt-get install --no-install-recommends -y -q \
    python3-minimal=3.10.6-1~22.04.1 \
    openssh-client=1:8.9p1-3ubuntu0.10 \
    sshpass=1.09-1 \
    rsync=3.2.7-0ubuntu0.22.04.2 \
    jq=1.6-2.1ubuntu3 \
    git=1:2.34.1-1ubuntu1.11
# tools used to install and configure packages that should not persist in this image
RUN apt-get install --no-install-recommends -y -q \
    python3-pip=22.0.2+dfsg-1ubuntu0.5

# non-root container user.
ARG CONTAINER_USER=ubuntu
ARG CONTAINER_USER_UID=1000
RUN if ! id -u ${CONTAINER_USER} &>/dev/null; \
	then useradd \
		--uid ${CONTAINER_USER_UID} \
		--user-group \
        --create-home \
		${CONTAINER_USER}; \
    fi
USER ${CONTAINER_USER}

# ansible and tools it uses
RUN PYTHONDONTWRITEBYTECODE=1 \
    pip3 install \
        --no-warn-script-location \
        --disable-pip-version-check \
        --no-cache-dir \
        --no-input \
        --progress-bar=off \
        --user \
    ansible==10.7.0 \
    docker==7.1.0 \
    botocore==1.35.89 \
    boto3==1.35.89 \
    github3.py==4.0.1 \
    passlib==1.7.4

# package cleanup
USER root
RUN apt-get remove --purge -y -q \
    python3-pip \
    apt-utils
RUN apt-get autoremove -y -q
RUN apt-get clean -y -q
RUN rm -rf /var/lib/apt/lists/*
USER ${CONTAINER_USER}}

###################
# application stage
###################
FROM ${BASEIMAGE} AS app
COPY --from=base / /

ARG CONTAINER_USER=ubuntu
USER ${CONTAINER_USER}
SHELL ["/bin/bash", "-c"]
ENV PATH=/home/${CONTAINER_USER}/.local/bin:${PATH}

# copy ansible configuration
COPY --chown=${CONTAINER_USER}:${CONTAINER_USER} ansible.cfg /home/${CONTAINER_USER}/ansible.cfg

# configure SSH
RUN mkdir -p /home/${CONTAINER_USER}/.ssh
COPY --chown=${CONTAINER_USER}:${CONTAINER_USER} ssh.config /home/${CONTAINER_USER}/.ssh/config

ENTRYPOINT ["ansible-playbook"]
