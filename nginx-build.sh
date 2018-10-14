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
else
    NGINX_VER=$NGINX_STABLE
fi

if [ "$NAXSI" = "y" ]; then
    NGX_NAXSI="--add-module=/usr/local/src/naxsi/naxsi_src "
else
    NGX_NAXSI=""
fi

if [ "$PAGESPEED" = "y" ]; then
    if [ "$PAGESPEED_RELEASE" = "1" ]; then
        NGX_PAGESPEED="--add-module=/usr/local/src/incubator-pagespeed-ngx-latest-beta "
    else
        NGX_PAGESPEED="--add-module=/usr/local/src/incubator-pagespeed-ngx-latest-stable "
    fi
else
    NGX_PAGESPEED=""
fi

if [ "$RTMP" = "y" ]; then
    NGINX_CC_OPT="--with-cc-opt='-m64 -g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wno-error=date-time -D_FORTIFY_SOURCE=2'"
    NGX_RTMP="--add-module=/usr/local/src/nginx-rtmp-module "
else
    NGX_RTMP=""
    NGINX_CC_OPT=([index]=--with-cc-opt='-m64 -g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2')
fi

##################################
# Install dependencies
##################################

echo -ne '       Installing dependencies               [..]\r'
sudo apt-get update >>/tmp/nginx-ee.log 2>&1
sudo apt-get install -y git build-essential libtool automake autoconf zlib1g-dev \
libpcre3 libpcre3-dev libgd-dev libssl-dev libxslt1-dev libxml2-dev libgeoip-dev libjemalloc1 libjemalloc-dev \
libbz2-1.0 libreadline-dev libbz2-dev libbz2-ocaml libbz2-ocaml-dev  software-properties-common sudo tar zlibc zlib1g zlib1g-dbg \
libcurl4-openssl-dev libgoogle-perftools-dev libperl-dev libpam0g-dev libbsd-dev zip unzip gnupg gnupg2 pigz libluajit-5.1-common \
libluajit-5.1-dev libmhash-dev libatomic-ops-dev libexpat-dev libgmp-dev autotools-dev bc checkinstall ccache curl debhelper dh-systemd libxml2  >>/tmp/nginx-ee.log 2>&1

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
    sudo apt-get -y install lsb-release >>/tmp/nginx-ee.log 2>&1
fi

# install gcc-7
distro_version=$(lsb_release -sc)

if [ "$NGINX_RELEASE" == "1" ] && [ "$RTMP" != "y" ]; then
    if [  "$distro_version" == "bionic" ]; then
        if [ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-8_1-bionic.list ] && [ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-bionic.list ]; then
            echo -ne '       Installing gcc-8                       [..]\r'
            {
                sudo add-apt-repository -y ppa:jonathonf/gcc-8.1
                sudo add-apt-repository -y ppa:jonathonf/gcc
                sudo apt-get update
                sudo apt-get install gcc-8 g++-8 -y
                sudo update-alternatives --remove-all gcc
                sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 80 --slave /usr/bin/g++ g++ /usr/bin/g++-8
            } >>/tmp/nginx-ee.log 2>&1
        fi
        elif [ "$distro_version" == "xenial" ]; then
        if [ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-8_1-xenial.list ] && [ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-xenial.list ]; then
            echo -ne '       Installing gcc-8                       [..]\r'
            sudo add-apt-repository -y ppa:jonathonf/gcc-8.1
            sudo add-apt-repository -y ppa:jonathonf/gcc
            sudo apt-get update
            sudo apt-get install gcc-8 g++-8 -y
            sudo update-alternatives --remove-all gcc
            sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 80 --slave /usr/bin/g++ g++ /usr/bin/g++-8
        fi
    fi
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
else
    if [ "$distro_version" == "xenial" ]; then
        if [ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-7_1-xenial.list ] && [ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-xenial.list ]; then
            echo -ne '       Installing gcc-7                       [..]\r'
            {
                sudo add-apt-repository -y ppa:jonathonf/gcc-7.1
                sudo add-apt-repository -y ppa:jonathonf/gcc
                sduo apt-get update -y
                sudo apt-get install gcc-7 g++-7 -y
                sudo update-alternatives --remove-all gcc
                sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 80 --slave /usr/bin/g++ g++ /usr/bin/g++-7
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
                sudo add-apt-repository -y ppa:jonathonf/ffmpeg-4
                sudo apt-get update
                sudo apt-get install ffmpeg -y
            fi
        else
            sudo apt-get install ffmpeg -y
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
rm -rf $DIR_SRC/*.tar.gz $DIR_SRC/nginx-1.* ipscrubtmp ipscrub $DIR_SRC/openssl $DIR_SRC/ngx_brotli $DIR_SRC/pcre $DIR_SRC/zlib

echo -ne '       Downloading additionals modules        [..]\r'

{
    # cache_purge module
    if [ -d $DIR_SRC/ngx_cache_purge ]; then
        git -C $DIR_SRC/ngx_cache_purge pull origin master
    else
        git clone https://github.com/FRiCKLE/ngx_cache_purge.git
    fi
    # memcached module
    if [ -d $DIR_SRC/memc-nginx-module ]; then
        git -C $DIR_SRC/memc-nginx-module pull origin master
    else
        git clone https://github.com/openresty/memc-nginx-module.git
    fi
    # devel kit
    if [ -d $DIR_SRC/ngx_devel_kit ]; then
        git -C $DIR_SRC/ngx_devel_kit pull origin master
    else
        git clone https://github.com/simpl/ngx_devel_kit.git
    fi
    # headers-more module
    if [ -d $DIR_SRC/headers-more-nginx-module ]; then
        git -C $DIR_SRC/headers-more-nginx-module pull origin master
    else
        git clone https://github.com/openresty/headers-more-nginx-module.git
    fi
    # echo module
    if [ -d $DIR_SRC/echo-nginx-module ]; then
        git -C $DIR_SRC/echo-nginx-module pull origin master
    else
        git clone https://github.com/openresty/echo-nginx-module.git
    fi
    # http_substitutions_filter module
    if [ -d $DIR_SRC/ngx_http_substitutions_filter_module ]; then
        git -C $DIR_SRC/ngx_http_substitutions_filter_module pull origin master
    else
        git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git
    fi
    # redis2 module
    if [ -d $DIR_SRC/redis2-nginx-module ]; then
        git -C $DIR_SRC/redis2-nginx-module pull origin master
    else
        git clone https://github.com/openresty/redis2-nginx-module.git
    fi
    # srcache module
    if [ -d $DIR_SRC/srcache-nginx-module ]; then
        git -C $DIR_SRC/srcache-nginx-module pull origin master
    else
        git clone https://github.com/openresty/srcache-nginx-module.git
    fi
    # set-misc module
    if [ -d $DIR_SRC/set-misc-nginx-module ]; then
        git -C $DIR_SRC/set-misc-nginx-module pull origin master
    else
        git clone https://github.com/openresty/set-misc-nginx-module.git
    fi
    # auth_pam module
    if [ -d $DIR_SRC/ngx_http_auth_pam_module ]; then
        git -C $DIR_SRC/ngx_http_auth_pam_module pull origin master
    else
        git clone https://github.com/sto/ngx_http_auth_pam_module.git
    fi
    # nginx-vts module
    if [ -d $DIR_SRC/nginx-module-vts ]; then
        git -C $DIR_SRC/nginx-module-vts pull origin master
    else
        git clone https://github.com/vozlt/nginx-module-vts.git
    fi
    # http redis module
    if [ ! -d $DIR_SRC/ngx_http_redis ]; then
        wget -qO ngx_http_redis.tar.gz https://people.freebsd.org/~osa/ngx_http_redis-0.3.8.tar.gz
        tar -I pigz -xf ngx_http_redis.tar.gz
        mv ngx_http_redis-0.3.8 ngx_http_redis
    fi
    if [ "$RTMP" = "y" ]; then
        if [ -d $DIR_SRC/nginx-rtmp-module ]; then
            git -C $DIR_SRC/nginx-rtmp-module pull origin master
        else
            git clone https://github.com/arut/nginx-rtmp-module.git
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
# Download zlib
##################################

cd $DIR_SRC || exit

echo -ne '       Downloading zlib                       [..]\r'

{
cd /usr/local/src || exit 1
wget -qO zlib.tar.gz http://zlib.net/zlib-1.2.11.tar.gz
tar -zxf zlib.tar.gz
mv zlib-1.2.11 zlib
}

if [ $? -eq 0 ]; then
    echo -ne "       Downloading zlib                       [${CGREEN}OK${CEND}]\\r"
    echo -ne '\n'
else
    echo -e "       Downloading zlib                       [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/nginx-ee.log"
    echo ""
    exit 1
fi

##################################
# Download zlib
##################################

cd $DIR_SRC || exit

echo -ne '       Downloading pcre                       [..]\r'

{

sudo wget -qO pcre.tar.gz https://ftp.pcre.org/pub/pcre/pcre-8.42.tar.gz
sudo tar -xvzf pcre.tar.gz
mv pcre-8.42 pcre

cd $DIR_SRC/pcre || exit 1
./configure --prefix=/usr \
--enable-utf8 \
--enable-unicode-properties \
--enable-pcre16 \
--enable-pcre32 \
--enable-pcregrep-libz \
--enable-pcregrep-libbz2 \
--enable-pcretest-libreadline \
--enable-jit

sudo make -j "$(nproc)"
sudo make install
mv -v /usr/lib/libpcre.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libpcre.so) /usr/lib/libpcre.so

} >>/tmp/nginx-ee.log 2>&1

if [ $? -eq 0 ]; then
    echo -ne "       Downloading pcre                       [${CGREEN}OK${CEND}]\\r"
    echo -ne '\n'
else
    echo -e "       Downloading pcre                       [${CRED}FAIL${CEND}]"
    echo ""
    echo "Please look at /tmp/nginx-ee.log"
    echo ""
    exit 1
fi

##################################
# Install Jemalloc
##################################

{
touch /etc/ld.so.preload
echo "/usr/lib/x86_64-linux-gnu/libjemalloc.so" | sudo tee --append /etc/ld.so.preload
} >>/tmp/nginx-ee.log 2>&1


##################################
# Download ngx_broti
##################################

cd $DIR_SRC || exit

echo -ne '       Downloading brotli                     [..]\r'
{
    git clone https://github.com/eustas/ngx_brotli
    cd ngx_brotli || exit 1
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
    sudo wget -qO openssl.tar.gz https://www.openssl.org/source/openssl-1.1.1.tar.gz
    sudo tar -xzf openssl.tar.gz
    mv openssl-1.1.1 openssl
    cd $DIR_SRC/openssl || exit 1
    curl -s https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-equal-1.1.1.patch | patch -p1
    curl -s https://raw.githubusercontent.com/centminmod/centminmod/master/patches/openssl/OpenSSL-1.1.1-reset-tls1.3-ciphers-SSL_CTX_set_ssl_version.patch | patch -p1
    curl -s https://raw.githubusercontent.com/centminmod/centminmod/master/patches/openssl/OpenSSL-1.1.1-sni-fix-delay-sig-algs.patch | patch -p1

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
        tar -I pigz -xf naxsi.tar.gz
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
    tar -I pigz -xf nginx.tar.gz
    mv nginx-${NGINX_VER} nginx
} >>/tmp/nginx-ee.log 2>&1

cd $DIR_SRC/nginx || exit

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
    {
        curl -s https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.15.5%2B.patch | patch -p1
        curl -s https://raw.githubusercontent.com/centminmod/centminmod/123.09beta01/patches/cloudflare/nginx-1.15.3_http2-hpack.patch | patch -p1
        curl -s https://raw.githubusercontent.com/kn007/patch/master/nginx_auto_using_PRIORITIZE_CHACHA.patch | patch -p1
    }>>/tmp/nginx-ee.log 2>&1
    #wget -qO nginx__dynamic_tls_records.patch https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.15.5%2B.patch >>/tmp/nginx-ee.log 2>&1
else
    wget -qO nginx__dynamic_tls_records.patch https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.13.0%2B.patch >>/tmp/nginx-ee.log 2>&1
fi
#patch -p1 <nginx__dynamic_tls_records.patch >>/tmp/nginx-ee.log 2>&1

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
    $NGX_NAXSI \
    "${NGINX_CC_OPT[@]}" \
    --with-ld-opt='-ljemalloc -Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now' \
    --prefix=/usr/share/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --lock-path=/var/lock/nginx.lock \
    --pid-path=/var/run/nginx.pid \
    --http-client-body-temp-path=/var/lib/nginx/body \
    --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
    --http-proxy-temp-path=/var/lib/nginx/proxy \
    --without-http_uwsgi_module \
    --without-mail_imap_module \
    --without-http_browser_module \
    --without-http_scgi_module \
    --without-http_split_clients_module \
    --without-http_ssi_module \
    --without-http_userid_module \
    --without-mail_pop3_module \
    --without-mail_smtp_module \
    --with-pcre=/usr/local/src/pcre \
    --with-pcre-jit \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-http_auth_request_module \
    --with-http_addition_module \
    --with-http_v2_hpack_enc \
    --with-http_geoip_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module \
    --with-http_v2_module \
    --with-http_sub_module \
    --with-http_xslt_module \
    --with-file-aio \
    --with-threads \
    --with-zlib=/usr/local/src/zlib \
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
    $NGX_PAGESPEED \
    $NGX_RTMP \
    --with-openssl=/usr/local/src/openssl \
    --with-openssl-opt='enable-ec_nistp_64_gcc_128 enable-tls1_3 no-nextprotoneg no-psk no-srp no-ssl2 no-ssl3 no-weak-ssl-ciphers zlib -ljemalloc -march=native -Wl,-flto' \
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
        sed -i 's/TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-256-GCM-SHA384:TLS13-AES-128-GCM-SHA256/TLS13+AESGCM+AES128/' /etc/nginx/nginx.conf
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
