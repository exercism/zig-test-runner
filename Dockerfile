FROM alpine:3.18 as builder

ARG VERSION=0.11.0
ARG RELEASE=zig-linux-x86_64-${VERSION}

RUN apk add --no-cache curl

WORKDIR /tmp
ADD https://ziglang.org/download/${VERSION}/${RELEASE}.tar.xz .
RUN tar -xvf ${RELEASE}.tar.xz \
    && mv /tmp/${RELEASE} /opt/zig

FROM alpine:3.18 as runner

# install packages required to run the tests
RUN apk add --no-cache bash jq

COPY --from=builder /opt/zig/ /opt/zig/
ENV PATH=$PATH:/opt/zig

WORKDIR /opt/test-runner
COPY . .
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
