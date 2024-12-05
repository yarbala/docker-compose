FROM grafana/promtail:latest

# Копируем конфигурационный файл
COPY config.yaml /etc/promtail/config.yaml

# Запускаем Promtail с использованием нашего конфигурационного файла
CMD ["-config.file=/etc/promtail/config.yaml"]
