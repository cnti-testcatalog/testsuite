FROM buildpack-deps:latest

COPY ./zombie.c /zombie.c

COPY ./test /test

RUN gcc zombie.c -o /zombie

ENTRYPOINT ["tail", "-f", "/dev/null"]

