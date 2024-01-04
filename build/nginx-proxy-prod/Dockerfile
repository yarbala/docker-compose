FROM nginxproxy/nginx-proxy:alpine

RUN { \
      echo 'server_tokens off;'; \
      echo 'client_max_body_size 100m;'; \
    } > /etc/nginx/conf.d/my_proxy.conf

RUN { \
      echo 'proxy_connect_timeout 1m;'; \
      echo 'proxy_read_timeout 1m;'; \
    } > /etc/nginx/conf.d/extended_timeout.conf

RUN mkdir /etc/nginx/htpasswd

COPY htpasswd/* /etc/nginx/htpasswd/
