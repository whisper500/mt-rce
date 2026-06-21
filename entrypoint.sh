#!/bin/sh
# Jalankan PHP-FPM di background
php-fpm -D

# Tunggu sebentar agar PHP-FPM siap
sleep 1

# Jalankan Nginx di foreground
nginx -g 'daemon off;'