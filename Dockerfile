FROM php:8.2-fpm-alpine

RUN apk add --no-cache nginx bash

WORKDIR /app

COPY . /app/
RUN chown -R nginx:nginx /app

COPY nginx.conf /etc/nginx/nginx.conf

RUN sed -i 's/^user = www-data/user = nginx/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/^group = www-data/group = nginx/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's|^listen = 127.0.0.1:9000|listen = 127.0.0.1:9000|' /usr/local/etc/php-fpm.d/www.conf

COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 80

CMD ["/app/entrypoint.sh"]