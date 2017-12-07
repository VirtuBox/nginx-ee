#!/bin/bash

apt-get install -y build-essential libtool automake autoconf zlib1g-dev libpcre3-dev libgd-dev libssl-dev libxslt1-dev libxml2-dev libgeoip-dev libgoogle-perftools-dev libperl-dev

rm -rf /usr/local/src/*
cd /usr/local/src

git clone https://github.com/FRiCKLE/ngx_cache_purge.git
git clone https://github.com/openresty/memc-nginx-module.git
git clone https://github.com/simpl/ngx_devel_kit.git
git clone https://github.com/openresty/headers-more-nginx-module.git
git clone https://github.com/openresty/echo-nginx-module.git
git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git
git clone https://github.com/openresty/redis2-nginx-module.git
git clone https://github.com/openresty/srcache-nginx-module.git
git clone https://github.com/openresty/set-misc-nginx-module.git
git clone https://github.com/FRiCKLE/ngx_coolkit.git
git clone https://github.com/FRiCKLE/ngx_slowfs_cache.git

wget https://people.freebsd.org/~osa/ngx_http_redis-0.3.8.tar.gz
tar -zxf ngx_http_redis-0.3.8.tar.gz
mv ngx_http_redis-0.3.8 ngx_http_redis

git clone https://github.com/google/ngx_brotli.git
cd ngx_brotli
git submodule update --init --recursive

cd /usr/local/src

git clone https://github.com/openssl/openssl.git
cd openssl
git checkout tls1.3-draft-18

cd /usr/local/src/

wget http://nginx.org/download/nginx-1.13.7.tar.gz
tar -xzvf nginx-1.13.7.tar.gz
mv nginx-1.13.7 nginx

cd /usr/local/src/nginx/

wget https://raw.githubusercontent.com/cujanovic/nginx-dynamic-tls-records-patch/master/nginx__dynamic_tls_records_1.11.5%2B.patch
patch -p1 < nginx__dynamic_tls_records_1.11.5*.patch
