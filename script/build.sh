#!/bin/bash
set -e

if [[ -z "${VERSION}" ]]; then
  echo "You must export the VERSION environment variable to build" >&2
  echo "See circle.yml for an example"
  exit 1
fi

. script/functions

# Build the authproxy.
smitty docker build \
  --build-arg VERSION=${VERSION} \
  -t duoauthproxy-builder \
  builder/

# Remove artifacts from previous runs.
smitty rm -fr duoauthproxy.tgz || :
docker rm -f builder &> /dev/null || :

# Create a tarball of built authproxy.
smitty docker run --name builder duoauthproxy-builder bash -c "tar czf /tmp/duoauthproxy.tgz /opt/duoauthproxy"

# Copy tarball into place and build runtime image.
smitty docker cp builder:/tmp/duoauthproxy.tgz runtime/
smitty docker build \
  --build-arg CI_BUILD_URL=${CIRCLE_BUILD_URL} \
  --build-arg VCS_REF=${VCS_REF} \
  --build-arg BUILD_DATE=${BUILD_DATE} \
  --build-arg VERSION=${VERSION} \
  -t duoauthproxy \
  runtime/
