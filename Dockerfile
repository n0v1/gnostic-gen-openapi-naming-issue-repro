ARG GO_VERSION="1.20.4"
ARG DEBIAN_VERSION="bullseye"

### Build Stage ###
FROM golang:$GO_VERSION-$DEBIAN_VERSION AS build-stage

# https://github.com/protocolbuffers/protobuf
ARG PROTOC_VERSION="23.1"

# https://github.com/google/gnostic
ARG OPENAPI_PLUGIN_VERSION="v0.6.9"

# https://github.com/googleapis/googleapis
ARG GOOGLE_API_VERSION="620a0237207496cefd53296f3528c65be14f0571"

# Install packages required for downloading and building dependencies
RUN apt-get update && apt-get install --no-install-recommends --assume-yes \
    unzip \
  && rm -rf /var/lib/apt/lists/*

# Download protoc binary
RUN mkdir -p /tmp/protoc \
  && wget -q -O /tmp/protoc/protoc.zip "https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOC_VERSION/protoc-$PROTOC_VERSION-linux-x86_64.zip" \
  && unzip /tmp/protoc/protoc.zip -d /tmp/protoc \
  && rm /tmp/protoc/protoc.zip

# Download and build protoc-gen-openapi plugin
RUN GOBIN=/tmp/bin/ go install "github.com/google/gnostic/cmd/protoc-gen-openapi@$OPENAPI_PLUGIN_VERSION"

# Download common google protos
RUN mkdir -p /tmp/googleapis \
  && wget -q -O - "https://github.com/googleapis/googleapis/archive/$GOOGLE_API_VERSION.tar.gz" \
  | tar --extract --ungzip --strip-components 1 --wildcards --directory=/tmp/googleapis "*.proto"


### Final Stage ###
FROM debian:$DEBIAN_VERSION-slim

# Copy required files from build stage
COPY --from=build-stage /tmp/protoc/bin/ /usr/local/bin/
COPY --from=build-stage /tmp/protoc/include/ /opt/include/
COPY --from=build-stage /tmp/bin/ /usr/local/bin/
COPY --from=build-stage /tmp/googleapis/google/api/ /opt/include/google/api/

ENTRYPOINT ["protoc", "--proto_path=/opt/include/"]
CMD ["--help"]
