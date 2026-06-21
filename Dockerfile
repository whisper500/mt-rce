# Gunakan image PHP 8.2 dengan FPM dan Nginx bawaan
FROM php:8.2-fpm-alpine

# Install dependensi yang diperlukan
RUN apk add --no-cache \
    nginx \
    supervisor \
    bash \
    curl \
    jq \
    coreutils \
    procps

# Buat direktori aplikasi
WORKDIR /app

# Salin seluruh file ke dalam container
COPY . /app/

# Pastikan binary dan script bisa dieksekusi
RUN chmod +x /app/mt-rce /app/mass-scan.sh /app/batch-domains.sh /app/worker.sh

# Buat direktori untuk data (volume akan di-mount di sini)
RUN mkdir -p /data/jobs /data/targets /data/outputs && chmod -R 777 /data

# Konfigurasi Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Konfigurasi PHP-FPM
RUN sed -i 's/^user = www-data/user = nginx/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/^group = www-data/group = nginx/' /usr/local/etc/php-fpm.d/www.conf

# Konfigurasi Supervisor
COPY supervisord.conf /etc/supervisord.conf

# Expose port web
EXPOSE 80

# Jalankan Supervisor yang akan menjalankan Nginx, PHP-FPM, dan Worker
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]