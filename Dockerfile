##################
## global arguments
##################

# image from which all other stages derive
ARG BASEIMAGE=ubuntu:22.04

##################
## OS base stage
##################

# derive from the appropriate base image depending on architecture
FROM --platform=linux/amd64 ${BASEIMAGE} AS base-amd64
FROM --platform=linux/arm64 ${BASEIMAGE} AS base-arm64
FROM scratch

##################
## dependencies stage
##################
# this stage installs all system dependencies as the root user
FROM base-${TARGETARCH} as base
USER root

# Preconfigure debconf for non-interactive installation - otherwise complains about terminal
# Avoid ERROR: invoke-rc.d: policy-rc.d denied execution of start.
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY localhost:0.0
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d

# apt dependencies and cleanup
RUN apt-get update -q
RUN apt-get install --no-install-recommends -y -q apt-utils 2>&1 \
	| grep -v "debconf: delaying package configuration"
RUN apt-get install --no-install-recommends -y -q \
    git \
    python3 \
    python3-pip \
    ssh
RUN apt-get autoremove -y -q
RUN apt-get clean -y -q
RUN rm -rf /var/lib/apt/lists/*

# python dependencies
ENV PYTHONDONTWRITEBYTECODE=1
RUN pip3 install --no-warn-script-location --upgrade \
    docker \
    ansible \
    boto3 \
    github3.py \
    passlib

###################
# application stage
###################
FROM base-${TARGETARCH} as app
COPY --from=base / /

# configure SSH
COPY ssh.config /root/.ssh/config
RUN chmod 0600 /root/.ssh/config

ENTRYPOINT ["ansible-playbook"]