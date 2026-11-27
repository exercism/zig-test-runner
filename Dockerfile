# target = alpine-latest
FROM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a AS builder


ARG VERSION=0.17.0
ARG RELEASE=zig-x86_64-linux-${VERSION}

# We can't reliably pin the package versions on Alpine, so we ignore the linter warning.
# See https://gitlab.alpinelinux.org/alpine/abuild/-/issues/9996
# hadolint ignore=DL3018
RUN apk add --no-cache curl

WORKDIR /tmp
ADD https://ziglang.org/download/${VERSION}/${RELEASE}.tar.xz .
RUN tar -xvf ${RELEASE}.tar.xz \
    && rm -rf /tmp/${RELEASE}/doc \
    && rm -rf /tmp/${RELEASE}/lib/libc/include/any-windows-any \
    && mv /tmp/${RELEASE} /opt/zig

FROM alpine:3.24.3@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a AS runner

# install packages required to run the tests
# hadolint ignore=DL3018
RUN apk add --no-cache bash gawk jq

RUN addgroup ziggroup \
    && adduser --disabled-password --gecos ziggy --ingroup ziggroup ziggy
COPY --from=builder --chown=ziggy:ziggroup /opt/zig/ /opt/zig/
ENV PATH=$PATH:/opt/zig

# hadolint ignore=DL3066
USER ziggy:ziggroup
WORKDIR /opt/test-runner
COPY --chown=ziggy:ziggroup bin/run.sh bin/test-metadata.awk bin/zir-cache.zig bin/
# Build the tool that keeps the cached ZIR valid on the machine that runs the
# image (see bin/zir-cache.zig). It uses its own cache, which is then removed,
# so the image's cache holds only what a test run needs.
RUN ZIG_GLOBAL_CACHE_DIR=/tmp/zir-cache-build zig build-exe -OReleaseSafe -fstrip \
        -target x86_64-linux-musl --cache-dir /tmp/zir-cache-build \
        -femit-bin=bin/zir-cache bin/zir-cache.zig \
    && rm -rf /tmp/zir-cache-build bin/zir-cache.zig
# Initialize a zig cache
COPY --chown=ziggy:ziggroup tests/example-success/example_success.zig init-zig-cache/
COPY --chown=ziggy:ziggroup tests/example-success/test_example_success.zig init-zig-cache/
# Setting ZIG_GLOBAL_CACHE_DIR makes run.sh warm the image's own cache instead
# of a copy of it.
# Then record which source file each cached ZIR file was made from.
RUN ZIG_GLOBAL_CACHE_DIR=/home/ziggy/.cache/zig bin/run.sh example-success init-zig-cache init-zig-cache \
    && rm -rf init-zig-cache/ \
    && bin/zir-cache record /home/ziggy/.cache/zig /opt/zig/lib zir-cache.list
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
