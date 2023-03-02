FROM buildpack-deps:20.04

RUN apt-get update && apt-get install -y psmisc strace

COPY ./init.c /init.c

COPY ./zombie.c /zombie.c

RUN gcc init.c -static -o /init

RUN gcc zombie.c -static -o /zombie

COPY ./entrypoint.sh /entrypoint.sh

#ENTRYPOINT ["/bin/sleep", "infinity"]

ENTRYPOINT ["/entrypoint.sh"]

