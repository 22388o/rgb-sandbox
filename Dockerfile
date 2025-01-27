ARG BUILDER_DIR=/srv/rgb


FROM rust:1.60.0-slim-bullseye as builder

ARG SRC_DIR=/usr/local/src/rgb
ARG BUILDER_DIR

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        build-essential cmake git pkg-config \
        libpq-dev libssl-dev libzmq3-dev libsqlite3-dev

WORKDIR "$SRC_DIR"

RUN cargo install rgb_node --version "=0.4.2" \
        --locked --all-features --root "${BUILDER_DIR}"


FROM debian:bullseye-slim

ARG BUILDER_DIR
ARG BIN_DIR=/usr/local/bin
ARG DATA_DIR=/var/lib/rgb
ARG USER=rgbd

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
       libsqlite3-0 \
       libssl1.1 \
       tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN adduser --home "${DATA_DIR}" --shell /bin/bash --disabled-login \
        --gecos "${USER} user" ${USER}

COPY --from=builder --chown=${USER}:${USER} \
     "${BUILDER_DIR}/bin/" "${BIN_DIR}"

WORKDIR "${BIN_DIR}"
USER ${USER}

VOLUME "$DATA_DIR"

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/rgbd", \
            "--bin-dir", "/usr/local/bin", "--data-dir", "/var/lib/rgb"]

CMD ["-vvvv"]
