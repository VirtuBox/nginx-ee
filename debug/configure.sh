#!/bin/bash

cd /usr/local/src/nginx

./configure \
 --with-cc-opt='-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2' \
 --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro' \
 --prefix=/usr/share/nginx  \
 --conf-path=/etc/nginx/nginx.conf \
 --http-log-path=/var/log/nginx/access.log \
 --error-log-path=/var/log/nginx/error.log \
 --lock-path=/var/lock/nginx.lock \
 --pid-path=/run/nginx.pid \
 --http-client-body-temp-path=/var/lib/nginx/body \
 --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
 --http-proxy-temp-path=/var/lib/nginx/proxy \
 --http-scgi-temp-path=/var/lib/nginx/scgi  \
 --http-uwsgi-temp-path=/var/lib/nginx/uwsgi  \
 --with-pcre-jit  \
 --with-http_ssl_module  \
 --with-http_stub_status_module  \
 --with-http_realip_module  \
 --with-http_auth_request_module  \
 --with-http_addition_module  \
 --with-http_geoip_module  \
 --with-http_gzip_static_module  \
 --with-http_image_filter_module  \
 --with-http_v2_module  \
 --with-http_sub_module  \
 --with-http_xslt_module  \
 --with-threads  \
 --add-module=/usr/local/src/ngx_cache_purge  \
 --add-module=/usr/local/src/memc-nginx-module \
 --add-module=/usr/local/src/ngx_devel_kit  \
 --add-module=/usr/local/src/headers-more-nginx-module \
 --add-module=/usr/local/src/echo-nginx-module  \
 --add-module=/usr/local/src/ngx_http_substitutions_filter_module  \
 --add-module=/usr/local/src/redis2-nginx-module  \
 --add-module=/usr/local/src/srcache-nginx-module  \
 --add-module=/usr/local/src/set-misc-nginx-module  \
 --add-module=/usr/local/src/ngx_http_redis   \
 --add-module=/usr/local/src/ngx_brotli  \
 --with-openssl=/usr/local/src/openssl \
 --with-openssl-opt=enable-tls1_3 \
 --sbin-path=/usr/sbin/nginx 
 
 
