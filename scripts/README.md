# Release

## Build Docker Images

```bash
# By default using FLAVORS=musa
PLATFORM=linux/amd64 DOCKER_ORG=mthreads ./scripts/build_docker.sh
# Using FLAVORS=vulkan
PLATFORM=linux/amd64 DOCKER_ORG=mthreads FLAVORS=vulkan ./scripts/build_docker.sh
PLATFORM=linux/arm64 DOCKER_ORG=mthreads FLAVORS=vulkan ./scripts/build_docker.sh
```

> *📝 The `UBUNTUVERSION` build argument specifies the Ubuntu version (e.g., `22.04`, `23.04`, `24.04`, `25.04`) used as the base image for Docker containers. This argument is only applicable when building images with the `vulkan` flavor.*

After running the build commands, Docker images will be created with tags in the following format:

```bash
<DOCKER_ORG>/ollama:<VERSION>-<FLAVOR>-<ARCH>
```

## Push Docker Images

```bash
# By default using FLAVORS=musa
PLATFORM=linux/amd64 DOCKER_ORG=mthreads ./scripts/push_docker_mthreads.sh
# Using FLAVORS=vulkan
PLATFORM=linux/amd64 DOCKER_ORG=mthreads FLAVORS=vulkan ./scripts/push_docker_mthreads.sh
PLATFORM=linux/arm64 DOCKER_ORG=mthreads FLAVORS=vulkan ./scripts/push_docker_mthreads.sh
DOCKER_ORG=mthreads FLAVORS=vulkan ./scripts/push_docker_mthreads.sh
```

## Build Artifacts

```bash
PLATFORM=linux/amd64 FLAVORS=musa ./scripts/build_linux_mthreads.sh
PLATFORM=linux/arm64 FLAVORS=vulkan ./scripts/build_linux_mthreads.sh
```
