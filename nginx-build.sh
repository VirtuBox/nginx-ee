#!/bin/bash
#
# Nginx-ee Bash script
# compile the latest nginx release from source with EasyEngine, Plesk or from scratch
#
# Version 3.1 - 2018-09-26
# Published & maintained by VirtuBox - https://virtubox.net
#
# Sources :
# https://github.com/VirtuBox/nginx-ee
#

# Check if user is root
if [ "$(id -u)" != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

# check if curl is installed

if [ ! -x /usr/bin/curl ]; then
    apt-get install curl >>/tmp/nginx-ee.log 2>&1
fi

##################################
# Variables
##################################

NAXSI_VER=0.56
DIR_SRC=/usr/local/src
NGINX_STABLE=1.14.0
NGINX_MAINLINE=$(curl -sL https://nginx.org/en/download.html 2>&1 | grep -E -o 'nginx\-[0-9.]+\.tar[.a-z]*' | awk -F "nginx-" '/.tar.gz$/ {print $2}' | sed -e 's|.tar.gz||g' | head -n 1 2>&1)
if [ ! -x /usr/sbin/nginx ]; then
    NGINX_CURRENT=$(nginx -v 2>&1 | awk -F "/" '{print $2}' | grep 1.15)
fi
OPENSSL_VER=OpenSSL_1_1_1

# Colors
CSI='\033['
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"

##################################
# Initial check & cleanup
##################################

# clean previous install log

echo "" >/tmp/nginx-ee.log

# detect Plesk
if [ -d /etc/psa ]; then
    NGINX_PLESK=1
    echo "Plesk installation detected"
else
    NGINX_PLESK=0
fi

# detect no nginx
if [ ! -d /etc/nginx ]; then
    NGINX_FROM_SCRATCH=1
else
    NGINX_FROM_SCRATCH=0
fi

# detect easyengine
if [ -d /etc/ee ]; then
    echo "EasyEngine installation detected"
    NGINX_EASYENGINE=1
else
    NGINX_EASYENGINE=0
fi

##################################
# Parse script arguments
##################################

while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        --pagespeed)
            PAGESPEED="y"
            shift
        ;;
        --pagespeed-beta)
            PAGESPEED="y"
            PAGESPEED_RELEASE="1"
            shift
        ;;
        --naxsi)
            NAXSI="y"
            shift
        ;;
        --rtmp)
            RTMP="y"
            shift
        ;;
        --latest | --mainline)
            NGINX_RELEASE=1
            shift
        ;;
        --stable)
            NGINX_RELEASE=2
            shift
        ;;
        *) ;;
    esac
    shift
done

##################################
# Installation menu
##################################

echo ""
echo "Welcome to the nginx-ee bash script."
echo ""

# interactive
if [ -z $NGINX_RELEASE ]; then
clear
    echo ""
    echo "Do you want to compile the latest Nginx Mainline [1] or Stable [2] Release ?"
    while [[ $NGINX_RELEASE != "1" && $NGINX_RELEASE != "2" ]]; do
        read -p "Select an option [1-2]: " NGINX_RELEASE
    done

    echo ""
    echo "Do you want Ngx_Pagespeed ? (y/n)"
    while [[ $PAGESPEED != "y" && $PAGESPEED != "n" ]]; do
        read -p "Select an option [y/n]: " PAGESPEED
    done
    echo ""
    if [ "$PAGESPEED" = "y" ]; then
        echo "Do you want to build the latest Pagespeed Beta [1] or Stable [2] Release ?"
        while [[ $PAGESPEED_RELEASE != "1" && $PAGESPEED_RELEASE != "2" ]]; do
            read -p "Select an option [1-2]: " PAGESPEED_RELEASE
        done
    fi
    echo ""
    echo "Do you want NAXSI WAF (still experimental)? (y/n)"
    while [[ $NAXSI != "y" && $NAXSI != "n" ]]; do
        read -p "Select an option [y/n]: " NAXSI
    done

    echo ""
    echo "Do you want RTMP streaming module ?"
    while [[ $RTMP != "y" && $RTMP != "n" ]]; do
        read -p "Select an option [y/n]: " RTMP
    done
    echo ""
fi



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
    if [ "$PAGESPEED_RELEASE" = "1" ]; then
        ngx_pagespeed="--add-module=/usr/local/src/incubator-pagespeed-ngx-latest-beta "
    else
        ngx_pagespeed="--add-module=/usr/local/src/incubator-pagespeed-ngx-latest-stable "
    fi
else
    ngx_pagespeed=""
fi

if [ "$RTMP" = "y" ]; then
    nginx_cc_opt=([index]=--with-cc-opt='-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wno-error=date-time -D_FORTIFY_SOURCE=2')
    ngx_rtmp="--add-module=/usr/local/src/nginx-rtmp-module "
else
    ngx_rtmp=""
    nginx_cc_opt=([index]=--with-cc-opt='-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2')
fi

##################################
# Install dependencies
##################################

echo -ne '       Installing dependencies               [..]\r'
apt-get update >>/tmp/nginx-ee.log 2>&1
apt-get install -y git build-essential libtool automake autoconf zlib1g-dev \
libpcre3-dev libgd-dev libssl-dev libxslt1-dev libxml2-dev libgeoip-dev \
libgoogle-perftools-dev libperl-dev libpam0g-dev libxslt1-dev libbsd-dev zip unzip gnupg gnupg2 >>/tmp/nginx-ee.log 2>&1

if [ $? -eq 0 ]; then
    echo -ne "       Installing dependencies                [${CGREEN}OK${CEND}]\\r"
    echo -ne '\n'
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

if [ $NGINX_FROM_SCRATCH = "1" ]; then

    git clone https://github.com/VirtuBox/nginx-config.git /etc/nginx
    mkdir -p /var/lib/nginx/{body,fastcgi,proxy,scgi,uwsgi}
    mkdir -p /var/run/nginx-cache
    mkdir -p /var/cache/nginx
    chown -R www-data:root /var/lib/nginx/* /var/cache/nginx /var/run/nginx-cache

    mkdir -p /var/www/html

    {

        wget -qO /var/www/html/index.nginx-debian.html https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/var/www/html/index.nginx-debian.html
        ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

        if [ ! -f /etc/systemd/system/multi-user.target.wants/nginx.service ] && [ ! -f /lib/systemd/system/nginx.service ]; then
            wget -qO /lib/systemd/system/nginx.service https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/etc/systemd/system/nginx.service
            systemctl enable nginx
        fi

    } >>/tmp/nginx-ee.log 2>&1

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

if [[ "$NGINX_RELEASE" == "1" && "$RTMP" != "y" ]]; then
    if [[ "$distro_version" == "xenial" || "$distro_version" == "bionic" ]]; then
        if [[ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-8_1-bionic.list && ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-8_1-xenial.list ]]; then
            echo -ne '       Installing gcc-8                       [..]\r'
            {
                apt-get install software-properties-common -y
                add-apt-repository ppa:jonathonf/gcc-8.1 -y
                apt-get update
                apt-get install gcc-8 g++-8 -y
            } >>/tmp/nginx-ee.log 2>&1
            if [ $? -eq 0 ]; then
                echo -ne "       Installing gcc-8                       [${CGREEN}OK${CEND}]\\r"
                echo -ne '\n'
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
            echo -ne '       Installing gcc-7                       [..]\r'
            {
                apt-get install software-properties-common -y
                add-apt-repository ppa:jonathonf/gcc-7.1 -y
                apt-get update
                apt-get install gcc-7 g++-7 -y
            } >>/tmp/nginx-ee.log 2>&1
            if [ $? -eq 0 ]; then
                echo -ne "       Installing gcc-7                       [${CGREEN}OK${CEND}]\\r"
                echo -ne '\n'
            else
                echo -e "        Installing gcc-7                      [${CRED}FAIL${CEND}]"
                echo ""
                echo "Please look at /tmp/nginx-ee.log"
                echo ""
                exit 1
            fi
        fi
    fi

fi

##################################
# Install ffmpeg for rtmp module
##################################

if [ "$RTMP" = "y" ]; then
    echo -ne '       Installing FFMPEG for RMTP module      [..]\r'
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
        echo -ne '\n'
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
rm -rf $DIR_SRC/*.tar.gz $DIR_SRC/nginx-1.* ipscrubtmp ipscrub $DIR_SRC/openssl

echo -ne '       Downloading additionals modules        [..]\r'

{
    # cache_purge module
    if [ -d $DIR_SRC/ngx_cache_purge ]; then
        git -C $DIR_SRC/ngx_cache_purge pull origin master;
    else
        git clone https://github.com/FRiCKLE/ngx_cache_purge.git;
    fi
    # memcached module
    if [ -d $DIR_SRC/memc-nginx-module ]; then
        git -C $DIR_SRC/memc-nginx-module pull origin master;
    else
        git clone https://github.com/openresty/memc-nginx-module.git;
    fi
    # devel kit
    if [ -d $DIR_SRC/ngx_devel_kit ]; then
        git -C $DIR_SRC/ngx_devel_kit pull origin master;
    else
        git clone https://github.com/simpl/ngx_devel_kit.git;
    fi
    # headers-more module
    if [ -d $DIR_SRC/headers-more-nginx-module ]; then
        git -C $DIR_SRC/headers-more-nginx-module pull origin master;
    else
        git clone https://github.com/openresty/headers-more-nginx-module.git;
    fi
    # echo module
    if [ -d $DIR_SRC/echo-nginx-module ]; then
        git -C $DIR_SRC/echo-nginx-module pull origin master;
    else
        git clone https://github.com/openresty/echo-nginx-module.git;
    fi
    # http_substitutions_filter module
    if [ -d $DIR_SRC/ngx_http_substitutions_filter_module ]; then
        git -C $DIR_SRC/ngx_http_substitutions_filter_module pull origin master;
    else
        git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git;
    fi
    # redis2 module
    if [ -d $DIR_SRC/redis2-nginx-module ]; then
        git -C $DIR_SRC/redis2-nginx-module pull origin master;
    else
        git clone https://github.com/openresty/redis2-nginx-module.git;
    fi
    # srcache module
    if [ -d $DIR_SRC/srcache-nginx-module ]; then
        git -C $DIR_SRC/srcache-nginx-module pull origin master;
    else
        git clone https://github.com/openresty/srcache-nginx-module.git;
    fi
    # set-misc module
    if [ -d $DIR_SRC/set-misc-nginx-module ]; then
        git -C $DIR_SRC/set-misc-nginx-module pull origin master;
    else
        git clone https://github.com/openresty/set-misc-nginx-module.git;
    fi
    # auth_pam module
    if [ -d $DIR_SRC/ngx_http_auth_pam_module ]; then
        git -C $DIR_SRC/ngx_http_auth_pam_module pull origin master;
    else
        git clone https://github.com/sto/ngx_http_auth_pam_module.git;
    fi
    # nginx-vts module
    if [ -d $DIR_SRC/nginx-module-vts ]; then
        git -C $DIR_SRC/nginx-module-vts pull origin master;
    else
        git clone https://github.com/vozlt/nginx-module-vts.git;
    fi
    # http redis module
    if [ ! -d $DIR_SRC/ngx_http_redis ]; then

        wget https://people.freebsd.org/~osa/ngx_http_redis-0.3.8.tar.gz
        tar -xzf ngx_http_redis-0.3.8.tar.gz
        mv ngx_http_redis-0.3.8 ngx_http_redis
    fi
    if [ "$RTMP" = "y" ]; then
        if [ -d $DIR_SRC/nginx-rtmp-module ]; then
            git -C $DIR_SRC/nginx-rtmp-module pull origin master;
        else
            git clone https://github.com/arut/nginx-rtmp-module.git;
        fi
    fi
    if [ $NGINX_PLESK = "0" ]; then
        # ipscrub module
        git clone https://github.com/masonicboom/ipscrub.git ipscrubtmp
        cp -rf $DIR_SRC/ipscrubtmp/ipscrub $DIR_SRC/ipscrub
    fi
} >>/tmp/nginx-ee.log 2>&1

if [ $? -eq 0 ]; then
    echo -ne "       Downloading additionals modules        [${CGREEN}OK${CEND}]\\r"
    echo -ne '\n'
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

echo -ne '       Downloading brotli                     [..]\r'
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
    echo -ne '\n'
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

echo -ne '       Downloading openssl                    [..]\r'

cd $DIR_SRC || exit
{
    git clone https://github.com/openssl/openssl.git
    git -C $DIR_SRC/openssl checkout $OPENSSL_VER
    if [ -d $DIR_SRC/openssl-patch ]; then
        { git -C $DIR_SRC/openssl-patch pull origin master; }
    else
        { git clone https://github.com/hakasenyang/openssl-patch.git; }
    fi
    cd $DIR_SRC/openssl || exit
    patch -p1 <../openssl-patch/openssl-equal-1.1.1_ciphers.patch
} >>/tmp/nginx-ee.log 2>&1

if [ $? -eq 0 ]; then
    echo -ne "       Downloading openssl                    [${CGREEN}OK${CEND}]\\r"
    echo -ne '\n'
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
    echo -ne '       Downloading naxsi                      [..]\r'
    {
        if [ -d $DIR_SRC/naxsi ]; then
            rm -rf $DIR_SRC/naxsi
        fi
        wget -qO naxsi.tar.gz https://github.com/nbs-system/naxsi/archive/$NAXSI_VER.tar.gz
        tar xvzf naxsi.tar.gz
        mv naxsi-$NAXSI_VER naxsi
    } >>/tmp/nginx-ee.log 2>&1

    if [ $? -eq 0 ]; then
        echo -ne "       Downloading naxsi                      [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
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
    echo -ne '       Downloading pagespeed                  [..]\r'

    {
        rm -rf incubator-pagespeed-* build_ngx_pagespeed.sh install
        wget -qO build_ngx_pagespeed.sh https://raw.githubusercontent.com/pagespeed/ngx_pagespeed/master/scripts/build_ngx_pagespeed.sh
        chmod +x build_ngx_pagespeed.sh
        if [ "$PAGESPEED_RELEASE" = "1" ]; then
            ./build_ngx_pagespeed.sh --ngx-pagespeed-version latest-beta -b $DIR_SRC
        else
            ./build_ngx_pagespeed.sh --ngx-pagespeed-version latest-stable -b $DIR_SRC
        fi
    } >>/tmp/nginx-ee.log 2>&1

    if [ $? -eq 0 ]; then
        echo -ne "       Downloading pagespeed                  [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
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
echo -ne '       Downloading nginx                      [..]\r'
if [ -d $DIR_SRC/nginx ]; then
    rm -rf $DIR_SRC/nginx
fi
{
    wget -qO nginx.tar.gz http://nginx.org/download/nginx-${NGINX_VER}.tar.gz
    tar -xzf nginx.tar.gz
    mv nginx-${NGINX_VER} nginx
} >>/tmp/nginx-ee.log 2>&1

cd $DIR_SRC/nginx/ || exit

if [ $? -eq 0 ]; then
    echo -ne "       Downloading nginx                      [${CGREEN}OK${CEND}]\\r"
    echo -ne '\n'
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

echo -ne '       Applying nginx patches                 [..]\r'

if [ $NGINX_RELEASE = "1" ]; then
    wget -qO nginx__dynamic_tls_records.patch https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.15.5%2B.patch >>/tmp/nginx-ee.log 2>&1
else
    wget -qO nginx__dynamic_tls_records.patch https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.13.0%2B.patch >>/tmp/nginx-ee.log 2>&1
fi
patch -p1 <nginx__dynamic_tls_records.patch >>/tmp/nginx-ee.log 2>&1
#wget -O nginx_hpack.patch $HPACK_VERSION >> /tmp/nginx-ee.log 2>&1
#patch -p1 <  nginx_hpack.patch >> /tmp/nginx-ee.log 2>&1

if [ $? -eq 0 ]; then
    echo -ne "       Applying nginx patches                 [${CGREEN}OK${CEND}]\\r"
    echo -ne '\n'
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

echo -ne '       Configuring nginx                      [..]\r'

if [[ "$distro_version" == "xenial" || "$distro_version" == "bionic" ]]; then
    if [[ "$NGINX_RELEASE" == "1" && "$RTMP" != "y" ]]; then
        export CC="/usr/bin/gcc-8"
        export CXX="/usr/bin/gc++-8"
    else
        export CC="/usr/bin/gcc-7"
        export CXX="/usr/bin/gc++-7"
    fi
fi

if [ $NGINX_PLESK = "0" ]; then

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

else

    ./configure \
    $ngx_naxsi \
    "${nginx_cc_opt[@]}" \
    --with-ld-opt='-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now' \
    --prefix=/etc/nginx \
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
    --user=nginx \
    --group=nginx \
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
    --add-module=/usr/local/src/ngx_http_auth_pam_module \
    --add-module=/usr/local/src/nginx-module-vts \
    $ngx_pagespeed \
    $ngx_rtmp \
    --with-openssl=/usr/local/src/openssl \
    --with-openssl-opt=enable-tls1_3 \
    --sbin-path=/usr/sbin/nginx >>/tmp/nginx-ee.log 2>&1
fi

if [ $? -eq 0 ]; then
    echo -ne "       Configuring nginx                      [${CGREEN}OK${CEND}]\\r"
    echo -ne '\n'
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

echo -ne '       Compiling nginx                        [..]\r'

{
    make -j "$(nproc)"
    make install
} >>/tmp/nginx-ee.log 2>&1

if [ $? -eq 0 ]; then
    echo -ne "       Compiling nginx                        [${CGREEN}OK${CEND}]\\r"
    echo -ne '\n'
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




if [ $NGINX_PLESK = "1" ]; then

    # block sw-nginx package updates from APT repository
    apt-mark hold sw-nginx >>/tmp/nginx-ee.log 2>&1

    elif [ $NGINX_EASYENGINE = "1" ]; then
    {
        # replace old TLS v1.3 ciphers suite
        sed -i 's/TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-256-GCM-SHA384:TLS13-AES-128-GCM-SHA256/TLS13+AESGCM+AES128/'  /etc/nginx/nginx.conf
        apt-mark hold nginx-ee nginx-common

    } >>/tmp/nginx-ee.log 2>&1
fi

{
    systemctl unmask nginx
    systemctl enable nginx

} >>/tmp/nginx-ee.log 2>&1

echo -ne '       Checking nginx configuration           [..]\r'

# check if nginx -t do not return errors
VERIFY_NGINX_CONFIG=$(nginx -t 2>&1 | grep failed)
if [ -z "$VERIFY_NGINX_CONFIG" ]; then
    {
        # make sure nginx.service is enable
        systemctl enable nginx
        # stop nginx to apply new service settings
        service nginx stop
        service nginx start
    } >>/tmp/nginx-ee.log 2>&1
    echo -ne "       Checking nginx configuration           [${CGREEN}OK${CEND}]\\r"
    echo -ne '\n'
else
    echo -e "       Checking nginx configuration           [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/nginx-ee.log or use the command nginx -t to find the issue"
    echo ""
fi
# We're done !
echo ""
echo -e "       ${CGREEN}Nginx ee was compiled successfully !${CEND}"
echo ""
echo ""
echo ""
echo "       Installation log : /tmp/nginx-ee.log"
