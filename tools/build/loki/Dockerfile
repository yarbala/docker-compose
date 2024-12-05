ARG LOKI_VERSION=3.0.0

FROM grafana/loki:${LOKI_VERSION}

COPY local-config.yaml /etc/loki/local-config.yaml

CMD ["-config.file=/etc/loki/local-config.yaml"]
