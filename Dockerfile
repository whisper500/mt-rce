FROM php:8.2-apache

# Install bash (opsional, untuk nanti)
RUN apt-get update && apt-get install -y bash && rm -rf /var/lib/apt/lists/*

# Salin file web ke DocumentRoot Apache
COPY index.php /var/www/html/

# Expose port 80
EXPOSE 80

# Apache otomatis dijalankan oleh image ini, tidak perlu CMD khusus