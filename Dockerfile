# SPDX-FileCopyrightText: (c) 2024 Xronos Inc.
# SPDX-License-Identifier: BSD-3-Clause

# syntax=docker/dockerfile:1

ARG BASEIMAGE=ubuntu:noble-20241118.1
ARG BUILDKIT_SBOM_SCAN_CONTEXT=false
ARG BUILDKIT_SBOM_SCAN_STAGE=false

###################
# application stage
###################
FROM ${BASEIMAGE} AS app
ARG BUILDKIT_SBOM_SCAN_STAGE=true
LABEL org.opencontainers.image.title="Xronos Ansible Distribution"
LABEL org.opencontainers.description="Xronos distribution of Ansible"
LABEL org.opencontainers.image.vendor="Xronos Inc"
LABEL org.opencontainers.image.authors="Jeff C. Jensen <11233838+elgeeko1@users.noreply.github.com>"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"
LABEL org.opencontainers.image.version="1.1.0"
LABEL org.opencontainers.image.url="https://hub.docker.com/r/xronosinc/ansible"
LABEL org.opencontainers.image.source="https://github.com/xronos-inc/ansible-docker"

COPY --from=base / /

ARG CONTAINER_USER=ubuntu
ENV CONTAINER_USER=${CONTAINER_USER}
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=localhost:0.0
ENV PATH=/home/${CONTAINER_USER}/.local/bin:${PATH}
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# SSH forwarding agent - map ssh agent socket to ~/.ssh/host-agent.sock
# in the container to use your agent with the container user
USER root
RUN echo "${CONTAINER_USER} ALL=(root) NOPASSWD:/usr/bin/socat *" | sudo tee /etc/sudoers.d/${CONTAINER_USER}
RUN chmod 0440 /etc/sudoers.d/${CONTAINER_USER}

USER ${CONTAINER_USER}
ENV VIRTUAL_ENV=/home/${CONTAINER_USER}/.venv
ENV PATH=/home/${CONTAINER_USER}/.venv/bin:${PATH}
WORKDIR /home/${CONTAINER_USER}

# ansible configuration
COPY --chown=${CONTAINER_USER}:${CONTAINER_USER} ansible.cfg /home/${CONTAINER_USER}/.ansible.cfg
RUN mkdir -p /home/${CONTAINER_USER}/.ansible

# configure SSH
RUN mkdir -p /home/${CONTAINER_USER}/.ssh
RUN chmod 700 /home/${CONTAINER_USER}/.ssh
COPY --chown=${CONTAINER_USER}:${CONTAINER_USER} --chmod=600 ssh.config /home/${CONTAINER_USER}/.ssh/config

# run entrypoint script and pass any arguments to it
COPY --chmod=755 environment.sh /
ENTRYPOINT ["/bin/bash", "-c", "source /environment.sh && ansible-playbook \"$@\"", "--"]
