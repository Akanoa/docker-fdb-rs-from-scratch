FROM rust:1.77 as builder
LABEL authors="Noa"

RUN apt update &&  \
    apt install -y wget adduser libclang-dev &&  \
    wget https://github.com/apple/foundationdb/releases/download/7.3.27/foundationdb-clients_7.3.27-1_amd64.deb && \
    dpkg -i foundationdb-clients_7.3.27-1_amd64.deb && \
    rm foundationdb-clients_7.3.27-1_amd64.deb

RUN wget https://github.com/upx/upx/releases/download/v4.2.3/upx-4.2.3-amd64_linux.tar.xz && \
    tar -xJf upx-4.2.3-amd64_linux.tar.xz && \
    mv upx-4.2.3-amd64_linux/upx /usr/bin/upx && \
    rm -fr upx-4.2.3-amd64_linux

RUN  cat <<EOF > /etc/foundationdb/fdb.cluster
docker:docker@foundationdb:4500
EOF

WORKDIR build

#https://gist.github.com/bcardiff/85ae47e66ff0df35a78697508fcb49af?permalink_comment_id=2078660#gistcomment-2078660
RUN ldd /bin/fdbcli | tr -s '[:blank:]' '\n' | grep '^/' | \
    xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;' \

RUN upx --best deps/lib/libfdb_c.so
RUN upx --best /bin/fdbcli

FROM scratch

COPY --from=builder /bin/fdbcli /bin/fdbcli
COPY --from=builder /etc/foundationdb/fdb.cluster /etc/foundationdb/fdb.cluster
COPY --from=builder /build/deps /


ENV LD_LIBRARY_PATH=/lib:/lib/x86_64-linux-gnu/

ENTRYPOINT ["/bin/fdbcli"]