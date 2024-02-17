# Ansible in Docker

Dockerfile used to build [xronosinc/ansible](https://hub.docker.com/repository/docker/xronosinc/ansible) docker image.

## Description

Dockerfile for Ansible. This dockerfile installs:

- ansible
- git (needed to install roles from private git repos)
- ssh (needed to install roles from private git repos)
- docker python module
- boto3 (support for some AWS features)
- github3.py (allows querying github repositories)

## Platform support

This dockerfile builds for:

- linux/amd64
- linux/arm64

## Build and run the image

```shell
docker build . -t xronosinc/ansible:latest
```

Run the image with the `--version` flag (equivalent to `ansible-playbook --version`):

```shell
docker run -it --tty --rm xronosinc/ansible:latest --version
```

`ansible-playbook` is the default entrypoint. Any additional arguments from the docker run command will be passed along. Alternately add the flag `--entrypoint /bin/bash` to open an interactive shell.

## Multiarch build

Build for multiple architectures using the [buildx](https://docs.docker.com/buildx/working-with-buildx/) command.

```shell
docker buildx build . --tag xronosinc/ansible:latest --platform linux/amd64,linux/arm64
```
