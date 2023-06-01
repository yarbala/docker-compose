FROM redis:latest

LABEL maintainer="Yarbala <yarbala@gmail.com>"

VOLUME /data

COPY redis.conf /usr/local/etc/redis/redis.conf

EXPOSE 6379

CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]

