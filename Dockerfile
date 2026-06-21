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

# Ubah kepemilikan folder web agar bisa dibaca nginx
RUN chown -R nginx:nginx /app/web

# Siapkan folder data dengan izin penuh (akan dioverride volume, tapi ini untuk fallback)
RUN mkdir -p /data/jobs /data/targets /data/outputs && chmod -R 777 /data

# Konfigurasi Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Konfigurasi PHP-FPM (user nginx, listen TCP)
RUN sed -i 's/^user = www-data/user = nginx/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/^group = www-data/group = nginx/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's|^listen = 127.0.0.1:9000|listen = 127.0.0.1:9000|' /usr/local/etc/php-fpm.d/www.conf

# Konfigurasi Supervisor
COPY supervisord.conf /etc/supervisord.conf

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]