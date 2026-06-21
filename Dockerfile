FROM php:8.2-fpm-alpine

RUN apk add --no-cache \
    nginx \
    supervisor \
    bash \
    curl \
    jq \
    coreutils \
    procps

WORKDIR /app
COPY . /app/

RUN chmod +x /app/mt-rce /app/mass-scan.sh /app/batch-domains.sh /app/worker.sh

RUN mkdir -p /data/jobs /data/targets /data/outputs && chmod -R 777 /data

COPY nginx.conf /etc/nginx/nginx.conf

RUN sed -i 's/^user = www-data/user = nginx/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/^group = www-data/group = nginx/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/^listen = 127.0.0.1:9000/listen = 127.0.0.1:9000/' /usr/local/etc/php-fpm.d/www.conf

# Pastikan socket juga bisa digunakan
RUN mkdir -p /var/run/php && chown nginx:nginx /var/run/php

COPY supervisord.conf /etc/supervisord.conf

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]