#!/bin/bash

# SPDX-FileCopyrightText: (c) 2024 Xronos Inc.
# SPDX-License-Identifier: BSD-3-Clause

set -e

platform=linux/amd64,linux/arm64

docker build . \
    -f Dockerfile.base \
    --target=base \
    --sbom=true \
    --provenance=true \
    --platform=${platform} \
    --tag base
docker build . \
    --target=app \
    --sbom=true \
    --provenance=true \
    --platform=${platform} \
    $@
