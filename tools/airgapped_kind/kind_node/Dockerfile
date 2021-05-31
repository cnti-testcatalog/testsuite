FROM kindest/node:v1.21.1

RUN mv /usr/local/bin/entrypoint /usr/local/bin/entrypoint-original
COPY entrypoint-wrapper.sh /usr/local/bin/entrypoint
