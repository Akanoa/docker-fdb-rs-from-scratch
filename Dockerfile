FROM rust:1.77 as builder
LABEL authors="Noa"

RUN apt update &&  \
    apt install -y wget adduser libclang-dev &&  \
    wget https://github.com/apple/foundationdb/releases/download/7.3.27/foundationdb-clients_7.3.27-1_amd64.deb && \
    dpkg -i foundationdb-clients_7.3.27-1_amd64.deb && \
    rm foundationdb-clients_7.3.27-1_amd64.deb

RUN  cat <<EOF > /etc/foundationdb/fdb.cluster
docker:docker@foundationdb:4500
EOF

WORKDIR build

ADD Cargo.toml Cargo.toml
COPY src src/

RUN cargo build --release

ENTRYPOINT ["top", "-b"]

FROM busybox

COPY --from=builder /build/target/release/docker-fdb /bin/app
COPY --from=builder /usr/bin/fdbcli /bin/fdbcli
COPY --from=builder /etc/foundationdb/fdb.cluster /etc/foundationdb/fdb.cluster
COPY --from=builder /lib/libfdb_c.so /lib/libfdb_c.so

RUN mkdir -p /lib/x86_64-linux-gnu/

COPY --from=builder /lib/x86_64-linux-gnu/libgcc_s.so.1 /lib/x86_64-linux-gnu/libgcc_s.so.1
COPY --from=builder /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6
COPY --from=builder /lib/x86_64-linux-gnu/librt.so.1 /lib/x86_64-linux-gnu/librt.so.1
COPY --from=builder /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/libdl.so.2
COPY --from=builder /lib/x86_64-linux-gnu/liblzma.so.5 /lib/x86_64-linux-gnu/liblzma.so.5
COPY --from=builder /lib/x86_64-linux-gnu/libz.so.1 /lib/x86_64-linux-gnu/libz.so.1
COPY --from=builder /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/libpthread.so.0

RUN chmod +x /bin/app

ENTRYPOINT ["top", "-b"]


#        libfdb_c.so => /lib/libfdb_c.so (0x00007ff3c77f9000)
#        libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007ff3c77d9000)
#        libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007ff3c76fa000)
#        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007ff3c7519000)
#        librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007ff3c7514000)
#        libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007ff3c750d000)
#        liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007ff3c74de000)
#        libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007ff3c74bf000)
#        libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007ff3c74ba000)
