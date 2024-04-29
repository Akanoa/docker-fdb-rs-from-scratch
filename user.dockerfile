FROM busybox as builder
ADD fs.tar /data

FROM busybox

COPY --from=builder /data/lib /lib/
COPY --from=builder /data/bin/app /bin/app
COPY --from=builder /data/etc/foundationdb/fdb.cluster /etc/foundationdb/fdb.cluster

ENV LD_LIBRARY_PATH=/lib:/lib/x86_64-linux-gnu/

ENTRYPOINT ["/bin/app", "/etc/foundationdb/fdb.cluster"]