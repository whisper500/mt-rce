FROM nginx:alpine

# Biarkan default.conf tetap ada!
# Salin file HTML ke direktori yang sudah dikonfigurasi default
COPY index.html /usr/share/nginx/html/

EXPOSE 80