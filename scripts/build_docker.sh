#!/bin/sh

set -eu

. $(dirname $0)/env.sh

# Set PUSH to a non-empty string to trigger push instead of load
PUSH=${PUSH:-""}

if [ -z "${PUSH}" ] ; then
    echo "Building ${FINAL_IMAGE_REPO}:$VERSION locally.  set PUSH=1 to push"
    LOAD_OR_PUSH="--load"
else
    echo "Will be pushing ${FINAL_IMAGE_REPO}:$VERSION"
    LOAD_OR_PUSH="--push"
fi

FLAVORS="musa"
if [ "${DOCKER_ORG}" != "mthreads" ]; then
    docker buildx build \
        ${LOAD_OR_PUSH} \
        --platform=${PLATFORM} \
        ${OLLAMA_COMMON_BUILD_ARGS} \
        -f Dockerfile \
        -t ${FINAL_IMAGE_REPO}:$VERSION \
        .
    FLAVORS="rocm musa"
fi


if echo $PLATFORM | grep "amd64" > /dev/null; then
    for FLAVOR in $FLAVORS; do
        docker buildx build \
            ${LOAD_OR_PUSH} \
            --platform=linux/amd64 \
            ${OLLAMA_COMMON_BUILD_ARGS} \
            --build-arg FLAVOR=${FLAVOR} \
            -f Dockerfile \
            -t ${FINAL_IMAGE_REPO}:$VERSION-${FLAVOR} \
            .
    done
fi