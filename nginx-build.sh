#!/bin/bash

# variables

NGINX_STABLE=1.14.0
NGINX_MAINLINE=$(curl -sL https://nginx.org/en/download.html 2>&1 | grep -E -o "nginx\\-[0-9.]+\\.tar[.a-z]*" | awk -F "nginx-" '/.tar.gz$/ {print $2}' | sed -e 's|.tar.gz||g' | head -n 1 2>&1)
NAXSI_VER=0.56
OPENSSL_VER=OpenSSL_1_1_1-pre8
DIR_SRC=/usr/local/src

# Colors
CSI="\\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"

# Check if user is root
if [ "$(id -u)" != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

clear

# additionals modules choice

echo ""
echo "Welcome to the nginx-ee bash script."
echo ""

echo ""
echo "Do you want to compile the latest Nginx Mainline [1] or Stable [2] Release ?"
while [[ $NGINX_RELEASE != "1" && $NGINX_RELEASE != "2" ]]; do
    read -p "Select an option [1-2]: " NGINX_RELEASE
done
echo ""
echo "Do you want Ngx_Pagespeed ? (y/n)"
while [[ $pagespeed != "y" && $pagespeed != "n" ]]; do
    read -p "Select an option [y/n]: " pagespeed
done
echo ""
echo ""
echo "Do you want NAXSI WAF (still experimental)? (y/n)"
while [[ $naxsi != "y" && $naxsi != "n" ]]; do
    read -p "Select an option [y/n]: " naxsi
done
echo ""


# set additionals modules

if   [ "$NGINX_RELEASE" = "1" ]
then
    NGINX_RELEASE=$NGINX_MAINLINE
    #HPACK_VERSION="https://raw.githubusercontent.com/centminmod/centminmod/123.09beta01/patches/cloudflare/nginx-1.15.0_http2-hpack.patch"
else
    NGINX_RELEASE=$NGINX_STABLE
    #HPACK_VERSION="https://raw.githubusercontent.com/centminmod/centminmod/123.09beta01/patches/cloudflare/nginx-1.14.0_http2-hpack.patch"
fi


if [ "$naxsi" = "y" ]
then
    ngx_naxsi="--add-module=/usr/local/src/naxsi/naxsi_src "
else
    ngx_naxsi=""
fi

if [ "$pagespeed" = "y" ]
then
    ngx_pagespeed="--add-module=/usr/local/src/incubator-pagespeed-ngx-latest-beta "
else
    ngx_pagespeed=""
fi

# Checking lsb_release package
if [ ! -x /usr/bin/lsb_release ]; then
    apt-get -y install lsb-release >> /tmp/nginx-ee.log 2>&1
fi

# install gcc-7 on Ubuntu 16.04 LTS
distro_version=$(lsb_release -sc)

if [ "$distro_version" == "xenial" ]; then
    if [ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-7_1-xenial.list ]; then
        echo -ne "       Installing gcc-7                      [..]\\r"
        {
            add-apt-repository ppa:jonathonf/gcc-7.1 -y
            apt-get update
            apt-get install gcc-7 g++-7  -y
        } >> /tmp/nginx-ee.log 2>&1
        
        export CC="/usr/bin/gcc-7"
        export CXX="/usr/bin/gc++-7"
        if [ $? -eq 0 ]; then
            echo -ne "       Installing gcc-7                      [${CGREEN}OK${CEND}]\\r"
            echo -ne "\\n"
        else
            echo -e "        Installing gcc-7                      [${CRED}FAIL${CEND}]"
            echo ""
            echo "Please look at /tmp/nginx-ee.log"
            echo ""
            exit 1
        fi
    fi
fi

## install prerequisites

echo -ne "       Installing dependencies               [..]\\r"
apt-get update >> /tmp/nginx-ee.log 2>&1
apt-get install -y git build-essential libtool automake autoconf zlib1g-dev \
libpcre3-dev libgd-dev libssl-dev libxslt1-dev libxml2-dev libgeoip-dev \
libgoogle-perftools-dev libperl-dev libpam0g-dev libxslt1-dev libbsd-dev zip unzip >> /tmp/nginx-ee.log 2>&1


if [ $? -eq 0 ]; then
    echo -ne "       Installing dependencies                [${CGREEN}OK${CEND}]\\r"
    echo -ne "\\n"
else
    echo -e "        Installing dependencies              [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/nginx-ee.log"
    echo ""
    exit 1
fi

## clean previous compilation

cd $DIR_SRC || exit
rm -rf ./\*.tar.gz ipscrubtmp ipscrub

## get additionals modules

echo -ne "       Downloading additionals modules        [..]\\r"

{
    if [ -d $DIR_SRC/ngx_cache_purge ]; then
        { git -C $DIR_SRC/ngx_cache_purge pull origin master; }
    else
        { git clone https://github.com/FRiCKLE/ngx_cache_purge.git; }
    fi
    if [ -d $DIR_SRC/memc-nginx-module ]; then
        { git -C $DIR_SRC/memc-nginx-module pull origin master; }
    else
        { git clone https://github.com/openresty/memc-nginx-module.git; }
    fi
    if [ -d $DIR_SRC/ngx_devel_kit ]; then
        { git -C $DIR_SRC/ngx_devel_kit pull origin master; }
    else
        { git clone https://github.com/simpl/ngx_devel_kit.git; }
    fi
    if [ -d $DIR_SRC/headers-more-nginx-module ]; then
        { git -C $DIR_SRC/headers-more-nginx-module pull origin master; }
    else
        { git clone https://github.com/openresty/headers-more-nginx-module.git; }
    fi
    if [ -d $DIR_SRC/echo-nginx-module ]; then
        { git -C $DIR_SRC/echo-nginx-module pull origin master; }
    else
        { git clone https://github.com/openresty/echo-nginx-module.git; }
    fi
    if [ -d $DIR_SRC/echo-nginx-module ]; then
        { git -C $DIR_SRC/echo-nginx-module pull origin master; }
    else
        { git clone https://github.com/openresty/echo-nginx-module.git; }
    fi
    if [ -d $DIR_SRC/ngx_http_substitutions_filter_module ]; then
        { git -C $DIR_SRC/ngx_http_substitutions_filter_module pull origin master; }
    else
        { git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git; }
    fi
    if [ -d $DIR_SRC/redis2-nginx-module ]; then
        { git -C $DIR_SRC/redis2-nginx-module pull origin master; }
    else
        { git clone https://github.com/openresty/redis2-nginx-module.git; }
    fi
    if [ -d $DIR_SRC/srcache-nginx-module ]; then
        { git -C $DIR_SRC/srcache-nginx-module pull origin master; }
    else
        { git clone https://github.com/openresty/srcache-nginx-module.git; }
    fi
    if [ -d $DIR_SRC/set-misc-nginx-module ]; then
        { git -C $DIR_SRC/set-misc-nginx-module pull origin master; }
    else
        { git clone https://github.com/openresty/set-misc-nginx-module.git; }
    fi
    if [ -d $DIR_SRC/ngx_http_auth_pam_module ]; then
        { git -C $DIR_SRC/ngx_http_auth_pam_module pull origin master; }
    else
        { git clone https://github.com/sto/ngx_http_auth_pam_module.git; }
    fi
    if [ -d $DIR_SRC/nginx-module-vts ]; then
        { git -C $DIR_SRC/nginx-module-vts pull origin master; }
    else
        { git clone https://github.com/vozlt/nginx-module-vts.git; }
    fi
    git clone https://github.com/masonicboom/ipscrub.git ipscrubtmp
    cp -rf $DIR_SRC/ipscrubtmp/ipscrub $DIR_SRC/ipscrub
} >> /tmp/nginx-ee.log 2>&1

cd $DIR_SRC || exit

if [ ! -d $DIR_SRC/ngx_http_redis ]; then
    {
        wget https://people.freebsd.org/~osa/ngx_http_redis-0.3.8.tar.gz
        tar -xzf ngx_http_redis-0.3.8.tar.gz
        mv ngx_http_redis-0.3.8 ngx_http_redis
    } >> /tmp/nginx-ee.log 2>&1
fi


if [ $? -eq 0 ]; then
    echo -ne "       Downloading additionals modules        [${CGREEN}OK${CEND}]\\r"
    echo -ne "\\n"
else
    echo -e "        Downloading additionals modules      [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/nginx-ee.log"
    echo ""
    exit 1
fi

# get brotli

cd $DIR_SRC || exit

echo -ne "       Downloading brotli                     [..]\\r"
{
    if [ -d $DIR_SRC/ngx_brotli ]; then
        { git -C $DIR_SRC/ngx_brotli pull origin master; }
    else
        { git clone https://github.com/google/ngx_brotli.git; }
    fi
    cd ngx_brotli || exit
    git submodule update --init --recursive
} >> /tmp/nginx-ee.log 2>&1

if [ $? -eq 0 ]; then
    echo -ne "       Downloading brotli                     [${CGREEN}OK${CEND}]\\r"
    echo -ne "\\n"
else
    echo -e "       Downloading brotli      [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/nginx-ee.log"
    echo ""
    exit 1
fi

## get openssl

echo -ne "       Downloading openssl                    [..]\\r"

cd $DIR_SRC || exit
if [ -d $DIR_SRC/openssl ]
then
    cd $DIR_SRC/openssl || exit
    git fetch >> /tmp/nginx-ee.log 2>&1
    git checkout $OPENSSL_VER >> /tmp/nginx-ee.log 2>&1
else
    git clone https://github.com/openssl/openssl.git >> /tmp/nginx-ee.log 2>&1
    cd $DIR_SRC/openssl || exit
    git checkout $OPENSSL_VER >> /tmp/nginx-ee.log 2>&1
fi



if [ $? -eq 0 ]; then
    echo -ne "       Downloading openssl                    [${CGREEN}OK${CEND}]\\r"
    echo -ne "\\n"
else
    echo -e "       Downloading openssl      [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/nginx-ee.log"
    echo ""
    exit 1
fi

## get naxsi
cd $DIR_SRC || exit
if [ "$naxsi" = "y" ]
then
    echo -ne "       Downloading naxsi                      [..]\\r"
    if [ -d $DIR_SRC/naxsi ]; then
        rm -rf $DIR_SRC/naxsi
    fi
    wget -O naxsi.tar.gz https://github.com/nbs-system/naxsi/archive/$NAXSI_VER.tar.gz >> /tmp/nginx-ee.log 2>&1
    tar xvzf naxsi.tar.gz >> /tmp/nginx-ee.log 2>&1
    mv naxsi-$NAXSI_VER naxsi
    
    
    if [ $? -eq 0 ]; then
        echo -ne "       Downloading naxsi                      [${CGREEN}OK${CEND}]\\r"
        echo -ne "\\n"
    else
        echo -e "       Downloading naxsi      [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/nginx-ee.log"
        echo ""
        exit 1
    fi
    
fi


## get ngx_pagespeed
cd $DIR_SRC || exit
if [ "$pagespeed" = "y" ]
then
    echo -ne "       Downloading pagespeed                  [..]\\r"
    {
        rm -rf incubator-pagespeed-ngx-latest-beta install
        wget https://ngxpagespeed.com/install
        chmod +x install
        ./install --ngx-pagespeed-version latest-beta -b $DIR_SRC
    } >> /tmp/nginx-ee.log 2>&1
    
    
    if [ $? -eq 0 ]; then
        echo -ne "       Downloading pagespeed                  [${CGREEN}OK${CEND}]\\r"
        echo -ne "\\n"
    else
        echo -e "       Downloading pagespeed                  [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/nginx-ee.log"
        echo ""
        exit 1
    fi
fi

## get nginx
cd $DIR_SRC || exit
echo -ne "       Downloading nginx                      [..]\\r"
if [ -d $DIR_SRC/nginx ]; then
    rm -rf $DIR_SRC/nginx
fi
wget http://nginx.org/download/nginx-${NGINX_RELEASE}.tar.gz >> /tmp/nginx-ee.log 2>&1
tar -xzvf nginx-${NGINX_RELEASE}.tar.gz >> /tmp/nginx-ee.log 2>&1
mv nginx-${NGINX_RELEASE} nginx

cd $DIR_SRC/nginx/ || exit

if [ $? -eq 0 ]; then
    echo -ne "       Downloading nginx                      [${CGREEN}OK${CEND}]\\r"
    echo -ne "\\n"
else
    echo -e "       Downloading nginx      [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/nginx-ee.log"
    echo ""
    exit 1
fi

## apply dynamic tls records patch

echo -ne "      applying nginx patches                 [..]\\r"

wget -O nginx__dynamic_tls_records.patch https://raw.githubusercontent.com/cujanovic/nginx-dynamic-tls-records-patch/master/nginx__dynamic_tls_records_1.13.0%2B.patch >> /tmp/nginx-ee.log 2>&1
patch -p1 < nginx__dynamic_tls_records.patch >> /tmp/nginx-ee.log 2>&1
#wget -O nginx_hpack.patch $HPACK_VERSION >> /tmp/nginx-ee.log 2>&1
#patch -p1 <  nginx_hpack.patch >> /tmp/nginx-ee.log 2>&1

if [ $? -eq 0 ]; then
    echo -ne "       applying nginx patches                 [${CGREEN}OK${CEND}]\\r"
    echo -ne "\\n"
else
    echo -e "        applying nginx patches                 [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/nginx-ee.log"
    echo ""
    exit 1
fi

## configuration

echo -ne "       Configuring nginx                      [..]\\r"

./configure \
$ngx_naxsi \
--with-cc-opt='-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2' \
--with-ld-opt='-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now' \
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
--with-file-aio \
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
--add-module=/usr/local/src/ipscrub   \
--add-module=/usr/local/src/ngx_http_auth_pam_module \
--add-module=/usr/local/src/nginx-module-vts \
$ngx_pagespeed \
--with-openssl=/usr/local/src/openssl \
--with-openssl-opt=enable-tls1_3 \
--sbin-path=/usr/sbin/nginx  >> /tmp/nginx-ee.log 2>&1

if [ $? -eq 0 ]; then
    echo -ne "       Configuring nginx                      [${CGREEN}OK${CEND}]\\r"
    echo -ne "\\n"
else
    echo -e "        Configuring nginx    [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/nginx-ee.log"
    echo ""
    exit 1
fi

## compilation

echo -ne "       Compile nginx                          [..]\\r"

make -j "$(nproc)" >> /tmp/nginx-ee.log 2>&1
make install >> /tmp/nginx-ee.log 2>&1

if [ $? -eq 0 ]; then
    echo -ne "       Compile nginx                          [${CGREEN}OK${CEND}]\\r"
    echo -ne "\\n"
else
    echo -e "        Compile nginx      [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/nginx-ee.log"
    echo ""
    exit 1
fi

## restart nginx with systemd

{
    systemctl unmask nginx
    systemctl enable nginx.service
    systemctl start nginx.service
    apt-mark hold nginx-ee nginx-common
    systemctl restart nginx
    nginx -t
    service nginx reload
} >> /tmp/nginx-ee.log 2>&1


# We're done !
echo ""
echo -e "       ${CGREEN}Nginx ee was compiled successfully !${CEND}"
echo ""
echo "       Installation log : /tmp/nginx-ee.log"
