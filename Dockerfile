ARG REPO=alpine
ARG IMAGE=3.18.3@sha256:c5c5fda71656f28e49ac9c5416b3643eaa6a108a8093151d6d1afc9463be8e33
FROM ${REPO}:${IMAGE} AS builder

ARG VERSION=0.11.0
ARG RELEASE=zig-linux-x86_64-${VERSION}

# We can't reliably pin the package versions on Alpine, so we ignore the linter warning.
# See https://gitlab.alpinelinux.org/alpine/abuild/-/issues/9996
# hadolint ignore=DL3018
RUN apk add --no-cache curl

WORKDIR /tmp
ADD https://ziglang.org/download/${VERSION}/${RELEASE}.tar.xz .
RUN tar -xvf ${RELEASE}.tar.xz \
    && rm -rf /tmp/${RELEASE}/doc \
    && mv /tmp/${RELEASE} /opt/zig

# install packages required to use `bin/run.sh`
# hadolint ignore=DL3018
RUN apk add --no-cache bash jq
ENV PATH=$PATH:/opt/zig
WORKDIR /opt/test-runner
COPY bin/run.sh bin/run.sh
# Initialize a zig cache
COPY tests/example-success/example_success.zig init-zig-cache/
COPY tests/example-success/test_example_success.zig init-zig-cache/
RUN bin/run.sh example-success init-zig-cache init-zig-cache \
    && rm -rf init-zig-cache/

FROM ${REPO}:${IMAGE} AS runner

# install packages required to run the tests
# hadolint ignore=DL3018
RUN apk add --no-cache bash jq

COPY --from=builder /opt/zig/ /opt/zig/
COPY --from=builder /root/.cache/zig/ /root/.cache/zig/
ENV PATH=$PATH:/opt/zig

WORKDIR /opt/test-runner
COPY bin/run.sh bin/run.sh
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
