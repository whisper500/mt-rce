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

# Pastikan semua script bisa dijalankan
RUN chmod +x /app/mt-rce /app/mass-scan.sh /app/batch-domains.sh /app/worker.sh

# Ubah kepemilikan seluruh /app ke nginx (nginx butuh akses baca php)
RUN chown -R nginx:nginx /app

# Siapkan folder data (volume akan di-mount di sini)
RUN mkdir -p /data/jobs /data/targets /data/outputs && chmod -R 777 /data

# Konfigurasi Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Konfigurasi PHP-FPM
RUN sed -i 's/^user = www-data/user = nginx/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/^group = www-data/group = nginx/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's|^listen = 127.0.0.1:9000|listen = 127.0.0.1:9000|' /usr/local/etc/php-fpm.d/www.conf

COPY supervisord.conf /etc/supervisord.conf

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]