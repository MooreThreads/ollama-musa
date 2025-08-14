#!/bin/sh

set -eux

. "$(dirname "$0")/env.sh"
for FLAVOR in $FLAVORS; do
    case "$FLAVOR" in
        musa)
            if [ "$PLATFORM" = "linux/amd64" ]; then
                MUSAVERSION="rc4.2.0"
                BASE_TAG="${FINAL_IMAGE_REPO}:${VERSION}-${FLAVOR}-$(basename "${PLATFORM}")"
                VERSIONED_TAG="${FINAL_IMAGE_REPO}:${VERSION}-${FLAVOR}-${MUSAVERSION}-$(basename "${PLATFORM}")"
                LATEST_TAG="${FINAL_IMAGE_REPO}:latest"

                docker tag "$BASE_TAG" "$VERSIONED_TAG"
                docker push "$VERSIONED_TAG"

                docker tag "$BASE_TAG" "$LATEST_TAG"
                docker push "$LATEST_TAG"
            else
                echo "Error: Unsupported PLATFORM for musa flavor: $PLATFORM" >&2
                exit 1
            fi
            ;;
        vulkan)
            MANIFEST_TAG="${FINAL_IMAGE_REPO}:${VERSION}-${FLAVOR}"
            if [ "$PLATFORM" = "linux/arm64,linux/amd64" ]; then
                AMD64_TAG="${MANIFEST_TAG}-amd64"
                ARM64_TAG="${MANIFEST_TAG}-arm64"

                docker manifest rm "$MANIFEST_TAG" || true
                docker manifest create "$MANIFEST_TAG" "$AMD64_TAG" "$ARM64_TAG"
                docker manifest push "$MANIFEST_TAG"
            else
                TAG="${MANIFEST_TAG}-$(basename "${PLATFORM}")"
                docker push "$TAG"
            fi
            ;;
        *)
            echo "Error: Unsupported FLAVOR: $FLAVOR" >&2
            exit 1
            ;;
    esac
done
