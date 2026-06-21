FROM nginx:alpine

# Hapus default config
RUN rm /etc/nginx/conf.d/default.conf

# Salin file HTML
COPY index.html /usr/share/nginx/html/

# Salin konfigurasi Nginx kustom (opsional, untuk nanti)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80