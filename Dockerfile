FROM php:8.2-fpm-alpine

# Install dependencies
RUN apk add --no-cache nginx supervisor bash curl jq

# Copy konfigurasi
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php.ini /usr/local/etc/php/conf.d/custom.ini

# Copy aplikasi
WORKDIR /app
COPY . .

# Pastikan binary dan script bisa dieksekusi
RUN chmod +x mt-rce mass-scan.sh batch-domains.sh worker.sh
RUN chmod -R 777 /app/web

# Buat direktori untuk data persistensi
VOLUME /data

# Expose port
EXPOSE 80

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]