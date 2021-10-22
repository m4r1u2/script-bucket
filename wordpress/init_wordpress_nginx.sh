#!/bin/bash -e

curl -LO https://wordpress.org/latest.tar.gz -o /tmp/latest.tar.gz
tar -xzf /tmp/latest.tar.gz -C /tmp/
mv /tmp/wordpress/* /var/www/html
rm -rf wordpress
chown -R www-data:www-data /var/www/html

cat > /var/www/html/wp-config.php<<EOF
<?php
define( 'DB_NAME', '_DB_NAME_' );
define( 'DB_USER', '_DB_USER_' );
define( 'DB_PASSWORD', '_DB_PASSWORD_' );
define( 'DB_HOST', '_DB_HOST_' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

EOF

curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/html/wp-config.php

cat >> /var/www/html/wp-config.php<<EOF

\$table_prefix = 'wp_';
define( 'WP_DEBUG', false );

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';

EOF

cat > /etc/nginx/sites-enabled/default<<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl default_server;
    ssl_protocols TLSv1.2 TLSv1.3;
    root /var/www/html;
    index index.php index.html index.nginx-debian.html;
    server_name _;
    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt { log_not_found off; access_log off; allow all; }
    location ~* \.(css|gif|ico|jpeg|jpg|js|png)\$ {
        expires max;
        log_not_found off;
    }
    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
    }
    location ~ /\.ht {
        deny all;
    }
}

EOF
