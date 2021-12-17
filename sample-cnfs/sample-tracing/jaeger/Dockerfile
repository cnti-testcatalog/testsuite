FROM jaegertracing/example-hotrod:latest AS builder


FROM debian:latest
RUN apt update && apt install -y curl bash 
COPY --from=builder /go/bin/hotrod-linux /bin/hotrod-linux
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
