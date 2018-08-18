#!/bin/bash

# Check if user is root
if [ "$(id -u)" != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

clear

# check if curl is installed

if [ ! -x /usr/bin/curl ]; then
    apt-get install curl >>/tmp/nginx-ee.log 2>&1
fi


##################################
# Variables
##################################

NAXSI_VER=0.56
OPENSSL_VER=OpenSSL_1_1_1-pre8
DIR_SRC=/usr/local/src
NGINX_STABLE=1.14.0
NGINX_MAINLINE=$(curl -sL https://nginx.org/en/download.html 2>&1 | grep -E -o "nginx\\-[0-9.]+\\.tar[.a-z]*" | awk -F "nginx-" '/.tar.gz$/ {print $2}' | sed -e 's|.tar.gz||g' | head -n 1 2>&1)


# Colors
CSI="\\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"

##################################
# Initial check & cleanup
##################################



# clean previous install log

echo "" >/tmp/nginx-ee.log

while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        -p|--pagespeed)  PAGESPEED="y"; shift;;
        -n|--naxsi)   NAXSI="y"; shift;;
        -r|--rtmp)   RTMP="y"; shift;;
        -m|--mainline)   NGINX_RELEASE=1; shift;;
        -s|--stable)   NGINX_RELEASE=2; shift;;
        -u|--update) NGINX_RELEASE=2; shift;;
        *)
    esac
    shift
done

##################################
# Installation menu
##################################

echo ""
echo "Welcome to the nginx-ee bash script."
echo ""
if [ -z  $NGINX_RELEASE ]; then
    echo ""
    echo "Do you want to compile the latest Nginx Mainline [1] or Stable [2] Release ?"
    while [[ $NGINX_RELEASE != "1" && $NGINX_RELEASE != "2" ]]; do
        read -p "Select an option [1-2]: " NGINX_RELEASE
    done
fi
if [ -z  $PAGESPEED ]; then
    echo ""
    echo "Do you want Ngx_Pagespeed ? (y/n)"
    while [[ $PAGESPEED != "y" && $PAGESPEED != "n" ]]; do
        read -p "Select an option [y/n]: " PAGESPEED
    done
fi
if [ -z  $NAXSI ]; then
    echo ""
    echo "Do you want NAXSI WAF (still experimental)? (y/n)"
    while [[ $NAXSI != "y" && $NAXSI != "n" ]]; do
        read -p "Select an option [y/n]: " NAXSI
    done
fi
if [ -z  $RTMP ]; then
    echo ""
    echo "Do you want RTMP streaming module ?"
    while [[ $RTMP != "y" && $RTMP != "n" ]]; do
        read -p "Select an option [y/n]: " RTMP
    done
fi
echo ""

##################################
# Set nginx release and modules
##################################

if [ "$NGINX_RELEASE" = "1" ]; then
    NGINX_VER=$NGINX_MAINLINE
    #HPACK_VERSION="https://raw.githubusercontent.com/centminmod/centminmod/123.09beta01/patches/cloudflare/nginx-1.15.0_http2-hpack.patch"
else
    NGINX_VER=$NGINX_STABLE
    #HPACK_VERSION="https://raw.githubusercontent.com/centminmod/centminmod/123.09beta01/patches/cloudflare/nginx-1.14.0_http2-hpack.patch"
fi

if [ "$NAXSI" = "y" ]; then
    ngx_naxsi="--add-module=/usr/local/src/naxsi/naxsi_src "
else
    ngx_naxsi=""
fi

if [ "$PAGESPEED" = "y" ]; then
    ngx_pagespeed="--add-module=/usr/local/src/incubator-pagespeed-ngx-latest-beta "
else
    ngx_pagespeed=""
fi

if [ "$RTMP" = "y" ]; then
    nginx_cc_opt=( [index]=--with-cc-opt='-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wno-error=date-time -D_FORTIFY_SOURCE=2' )
    ngx_rtmp="--add-module=/usr/local/src/nginx-rtmp-module "
else
    ngx_rtmp=""
    nginx_cc_opt=( [index]=--with-cc-opt='-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2' )
fi

##################################
# Install dependencies
##################################

echo -ne "       Installing dependencies               [..]\\r"
apt-get update >>/tmp/nginx-ee.log 2>&1
apt-get install -y git build-essential libtool automake autoconf zlib1g-dev \
libpcre3-dev libgd-dev libssl-dev libxslt1-dev libxml2-dev libgeoip-dev \
libgoogle-perftools-dev libperl-dev libpam0g-dev libxslt1-dev libbsd-dev zip unzip curl gnupg2 >>/tmp/nginx-ee.log 2>&1

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

##################################
# Checking install type
##################################

if [ ! -d /etc/nginx ]; then

    mkdir -p /etc/nginx/{conf.d,common,sites-available,sites-enabled}

    wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/VirtuBox/nginx-ee/develop/etc/nginx/nginx.conf
    wget -O /etc/nginx/sites-available/default https://raw.githubusercontent.com/VirtuBox/ubuntu-nginx-web-server/master/etc/nginx/sites-available/default
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

fi



##################################
# Install gcc7 or gcc8 from PPA
##################################
# gcc7 for nginx stable on Ubuntu 16.04 LTS
# gcc8 for nginx mainline on Ubuntu 16.04 LTS & 18.04 LTS

# Checking lsb_release package
if [ ! -x /usr/bin/lsb_release ]; then
    apt-get -y install lsb-release >>/tmp/nginx-ee.log 2>&1
fi

# install gcc-7
distro_version=$(lsb_release -sc)

if [[ "$NGINX_RELEASE" = "1" && "$RTMP" = "n" ]]; then
    if [[ "$distro_version" == "xenial" || "$distro_version" == "bionic" ]]; then
        if [[ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-8_1-bionic.list || ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-8_1-xenial.list ]]; then
            echo -ne "       Installing gcc-8                       [..]\\r"
            {
                apt-get install software-properties-common -y
                add-apt-repository ppa:jonathonf/gcc-8.1 -y
                apt-get update
                apt-get install gcc-8 g++-8 -y
            } >>/tmp/nginx-ee.log 2>&1

            export CC="/usr/bin/gcc-8"
            export CXX="/usr/bin/gc++-8"
            if [ $? -eq 0 ]; then
                echo -ne "       Installing gcc-8                       [${CGREEN}OK${CEND}]\\r"
                echo -ne "\\n"
            else
                echo -e "        Installing gcc-8                      [${CRED}FAIL${CEND}]"
                echo ""
                echo "Please look at /tmp/nginx-ee.log"
                echo ""
                exit 1
            fi
        fi
    fi
else
    if [ "$distro_version" == "xenial" ]; then
        if [ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-7_1-xenial.list ]; then
            echo -ne "       Installing gcc-7                       [..]\\r"
            {
                apt-get install software-properties-common -y
                add-apt-repository ppa:jonathonf/gcc-7.1 -y
                apt-get update
                apt-get install gcc-7 g++-7 -y
            } >>/tmp/nginx-ee.log 2>&1

            export CC="/usr/bin/gcc-7"
            export CXX="/usr/bin/gc++-7"
            if [ $? -eq 0 ]; then
                echo -ne "       Installing gcc-7                       [${CGREEN}OK${CEND}]\\r"
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
    if [ "$distro_version" == "bionic" ]; then
        export CC="/usr/bin/gcc-7"
        export CXX="/usr/bin/gc++-7"
    fi

fi

##################################
# Install ffmpeg for rtmp module
##################################

if [ "$RTMP" = "y" ]; then
    echo -ne "       Installing FFMPEG for RMTP module      [..]\\r"
    {
        if [ "$distro_version" == "xenial" ]; then
            if [ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-ffmpeg-4-xenial.list ]; then
                apt-get install software-properties-common -y
                add-apt-repository ppa:jonathonf/ffmpeg-4 -y
                apt-get update
                apt-get install ffmpeg -y
            fi
        else
            apt-get install ffmpeg -y
        fi
    } >>/tmp/nginx-ee.log 2>&1
    if [ $? -eq 0 ]; then
        echo -ne "       Installing FFMPEG for RMTP module      [${CGREEN}OK${CEND}]\\r"
        echo -ne "\\n"
    else
        echo -e "       Installing FFMPEG for RMTP module      [${CRED}FAIL${CEND}]"
        echo ""
        echo "Please look at /tmp/nginx-ee.log"
        echo ""
        exit 1
    fi
fi

##################################
# Download additional modules
##################################

# clear previous compilation archives

cd $DIR_SRC || exit
rm -rf $DIR_SRC/*.tar.gz $DIR_SRC/nginx-1.* ipscrubtmp ipscrub

echo -ne "       Downloading additionals modules        [..]\\r"

{
    # cache_purge module
    if [ -d $DIR_SRC/ngx_cache_purge ]; then
        { git -C $DIR_SRC/ngx_cache_purge pull origin master; }
    else
        { git clone https://github.com/FRiCKLE/ngx_cache_purge.git; }
    fi
    # memcached module
    if [ -d $DIR_SRC/memc-nginx-module ]; then
        { git -C $DIR_SRC/memc-nginx-module pull origin master; }
    else
        { git clone https://github.com/openresty/memc-nginx-module.git; }
    fi
    # devel kit
    if [ -d $DIR_SRC/ngx_devel_kit ]; then
        { git -C $DIR_SRC/ngx_devel_kit pull origin master; }
    else
        { git clone https://github.com/simpl/ngx_devel_kit.git; }
    fi
    # headers-more module
    if [ -d $DIR_SRC/headers-more-nginx-module ]; then
        { git -C $DIR_SRC/headers-more-nginx-module pull origin master; }
    else
        { git clone https://github.com/openresty/headers-more-nginx-module.git; }
    fi
    # echo module
    if [ -d $DIR_SRC/echo-nginx-module ]; then
        { git -C $DIR_SRC/echo-nginx-module pull origin master; }
    else
        { git clone https://github.com/openresty/echo-nginx-module.git; }
    fi
    # http_substitutions_filter module
    if [ -d $DIR_SRC/ngx_http_substitutions_filter_module ]; then
        { git -C $DIR_SRC/ngx_http_substitutions_filter_module pull origin master; }
    else
        { git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git; }
    fi
    # redis2 module
    if [ -d $DIR_SRC/redis2-nginx-module ]; then
        { git -C $DIR_SRC/redis2-nginx-module pull origin master; }
    else
        { git clone https://github.com/openresty/redis2-nginx-module.git; }
    fi
    # srcache module
    if [ -d $DIR_SRC/srcache-nginx-module ]; then
        { git -C $DIR_SRC/srcache-nginx-module pull origin master; }
    else
        { git clone https://github.com/openresty/srcache-nginx-module.git; }
    fi
    # set-misc module
    if [ -d $DIR_SRC/set-misc-nginx-module ]; then
        { git -C $DIR_SRC/set-misc-nginx-module pull origin master; }
    else
        { git clone https://github.com/openresty/set-misc-nginx-module.git; }
    fi
    # auth_pam module
    if [ -d $DIR_SRC/ngx_http_auth_pam_module ]; then
        { git -C $DIR_SRC/ngx_http_auth_pam_module pull origin master; }
    else
        { git clone https://github.com/sto/ngx_http_auth_pam_module.git; }
    fi
    # nginx-vts module
    if [ -d $DIR_SRC/nginx-module-vts ]; then
        { git -C $DIR_SRC/nginx-module-vts pull origin master; }
    else
        { git clone https://github.com/vozlt/nginx-module-vts.git; }
    fi
    # http redis module
    if [ ! -d $DIR_SRC/ngx_http_redis ]; then

        wget https://people.freebsd.org/~osa/ngx_http_redis-0.3.8.tar.gz
        tar -xzf ngx_http_redis-0.3.8.tar.gz
        mv ngx_http_redis-0.3.8 ngx_http_redis
    fi
    if [ "$RTMP" = "y" ]; then
        if [ -d $DIR_SRC/nginx-rtmp-module ]; then
            { git -C $DIR_SRC/nginx-rtmp-module pull origin master; }
        else
            { git clone https://github.com/arut/nginx-rtmp-module.git; }
        fi
    fi
    if [ ! -d /etc/psa ]; then
        # ipscrub module
        git clone https://github.com/masonicboom/ipscrub.git ipscrubtmp
        cp -rf $DIR_SRC/ipscrubtmp/ipscrub $DIR_SRC/ipscrub
    fi
} >>/tmp/nginx-ee.log 2>&1

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

##################################
# Download ngx_broti
##################################

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
} >>/tmp/nginx-ee.log 2>&1

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

##################################
# Download OpenSSL
##################################

echo -ne "       Downloading openssl                    [..]\\r"

cd $DIR_SRC || exit
{
    if [ -d $DIR_SRC/openssl ]; then
        cd $DIR_SRC/openssl || exit
        git fetch
        git checkout $OPENSSL_VER
    else
        git clone https://github.com/openssl/openssl.git
        cd $DIR_SRC/openssl || exit
        git checkout $OPENSSL_VER
    fi
} >>/tmp/nginx-ee.log 2>&1

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

##################################
# Download Naxsi
##################################

cd $DIR_SRC || exit
if [ "$NAXSI" = "y" ]; then
    echo -ne "       Downloading naxsi                      [..]\\r"
    {
        if [ -d $DIR_SRC/naxsi ]; then
            rm -rf $DIR_SRC/naxsi
        fi
        wget -O naxsi.tar.gz https://github.com/nbs-system/naxsi/archive/$NAXSI_VER.tar.gz
        tar xvzf naxsi.tar.gz
        mv naxsi-$NAXSI_VER naxsi
    } >>/tmp/nginx-ee.log 2>&1

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

##################################
# Download Pagespeed
##################################

cd $DIR_SRC || exit
if [ "$PAGESPEED" = "y" ]; then
    echo -ne "       Downloading pagespeed                  [..]\\r"

    {
        rm -rf incubator-pagespeed-ngx-latest-beta build_ngx_pagespeed.sh install
        wget https://raw.githubusercontent.com/pagespeed/ngx_pagespeed/master/scripts/build_ngx_pagespeed.sh
        chmod +x build_ngx_pagespeed.sh
        ./build_ngx_pagespeed.sh --ngx-pagespeed-version latest-beta -b $DIR_SRC
    } >>/tmp/nginx-ee.log 2>&1

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

##################################
# Download Nginx
##################################

cd $DIR_SRC || exit
echo -ne "       Downloading nginx                      [..]\\r"
if [ -d $DIR_SRC/nginx ]; then
    rm -rf $DIR_SRC/nginx
fi
{
    wget http://nginx.org/download/nginx-${NGINX_VER}.tar.gz
    tar -xzf nginx-${NGINX_VER}.tar.gz
    mv nginx-${NGINX_VER} nginx
} >>/tmp/nginx-ee.log 2>&1

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

##################################
# Apply Nginx patches
##################################

echo -ne "       Applying nginx patches                 [..]\\r"

wget -O nginx__dynamic_tls_records.patch https://raw.githubusercontent.com/cujanovic/nginx-dynamic-tls-records-patch/master/nginx__dynamic_tls_records_1.13.0%2B.patch >>/tmp/nginx-ee.log 2>&1
patch -p1 <nginx__dynamic_tls_records.patch >>/tmp/nginx-ee.log 2>&1
#wget -O nginx_hpack.patch $HPACK_VERSION >> /tmp/nginx-ee.log 2>&1
#patch -p1 <  nginx_hpack.patch >> /tmp/nginx-ee.log 2>&1

if [ $? -eq 0 ]; then
    echo -ne "       Applying nginx patches                 [${CGREEN}OK${CEND}]\\r"
    echo -ne "\\n"
else
    echo -e "       Applying nginx patches                 [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/nginx-ee.log"
    echo ""
    exit 1
fi

##################################
# Configure Nginx
##################################

echo -ne "       Configuring nginx                      [..]\\r"

./configure \
$ngx_naxsi \
"${nginx_cc_opt[@]}" \
--with-ld-opt='-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now' \
--prefix=/usr/share/nginx \
--conf-path=/etc/nginx/nginx.conf \
--http-log-path=/var/log/nginx/access.log \
--error-log-path=/var/log/nginx/error.log \
--lock-path=/var/lock/nginx.lock \
--pid-path=/var/run/nginx.pid \
--http-client-body-temp-path=/var/lib/nginx/body \
--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
--http-proxy-temp-path=/var/lib/nginx/proxy \
--http-scgi-temp-path=/var/lib/nginx/scgi \
--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
--with-pcre-jit \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_realip_module \
--with-http_auth_request_module \
--with-http_addition_module \
--with-http_geoip_module \
--with-http_gzip_static_module \
--with-http_image_filter_module \
--with-http_v2_module \
--with-http_sub_module \
--with-http_xslt_module \
--with-file-aio \
--with-threads \
--add-module=/usr/local/src/ngx_cache_purge \
--add-module=/usr/local/src/memc-nginx-module \
--add-module=/usr/local/src/ngx_devel_kit \
--add-module=/usr/local/src/headers-more-nginx-module \
--add-module=/usr/local/src/echo-nginx-module \
--add-module=/usr/local/src/ngx_http_substitutions_filter_module \
--add-module=/usr/local/src/redis2-nginx-module \
--add-module=/usr/local/src/srcache-nginx-module \
--add-module=/usr/local/src/set-misc-nginx-module \
--add-module=/usr/local/src/ngx_http_redis \
--add-module=/usr/local/src/ngx_brotli \
--add-module=/usr/local/src/ipscrub \
--add-module=/usr/local/src/ngx_http_auth_pam_module \
--add-module=/usr/local/src/nginx-module-vts \
$ngx_pagespeed \
$ngx_rtmp \
--with-openssl=/usr/local/src/openssl \
--with-openssl-opt=enable-tls1_3 \
--sbin-path=/usr/sbin/nginx >>/tmp/nginx-ee.log 2>&1

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

##################################
# Compile Nginx
##################################

echo -ne "       Compiling nginx                        [..]\\r"

{
    make -j "$(nproc)"
    make install
} >>/tmp/nginx-ee.log 2>&1

if [ $? -eq 0 ]; then
    echo -ne "       Compiling nginx                        [${CGREEN}OK${CEND}]\\r"
    echo -ne "\\n"
else
    echo -e "        Compile nginx      [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/nginx-ee.log"
    echo ""
    exit 1
fi

##################################
# Perform final tasks
##################################

{
    systemctl unmask nginx
    systemctl enable nginx.service
    systemctl start nginx.service
    apt-mark hold nginx-ee nginx-common
    systemctl restart nginx
    nginx -t
    service nginx reload
} >>/tmp/nginx-ee.log 2>&1

# We're done !
echo ""
echo -e "       ${CGREEN}Nginx ee was compiled successfully !${CEND}"
echo ""
echo "       Installation log : /tmp/nginx-ee.log"
