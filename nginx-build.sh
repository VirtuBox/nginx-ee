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
[ "$(id -u)" != "0" ] && {
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
}

# check if curl is installed

[ ! -x /usr/bin/curl ] && {
    apt-get install curl
}>>/tmp/nginx-ee.log 2>&1


##################################
# Variables
##################################

NAXSI_VER=0.56
DIR_SRC=/usr/local/src
NGINX_STABLE=1.14.1
NGINX_MAINLINE=$(curl -sL https://nginx.org/en/download.html 2>&1 | grep -E -o 'nginx\-[0-9.]+\.tar[.a-z]*' | awk -F "nginx-" '/.tar.gz$/ {print $2}' | sed -e 's|.tar.gz||g' | head -n 1 2>&1)

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
[ -d /etc/psa ] && {
    NGINX_PLESK=1
    echo "Plesk installation detected"
}


# detect easyengine
[ -d /etc/ee ] && {
    echo "EasyEngine installation detected"
    NGINX_EASYENGINE=1
}


[ ! -x /usr/sbin/nginx ] && {
    NGINX_FROM_SCRATCH=1
    echo "No Plesk or EasyEngine installation detected"
}





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
        echo "Do you prefer to build the latest Pagespeed Beta [1] or Stable [2] Release ?"
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
    NGX_HPACK="--with-http_v2_hpack_enc"
else
    NGINX_VER=$NGINX_STABLE
    NGX_HPACK=""
fi

if [ "$RTMP" = "y" ]; then
    NGINX_CC_OPT=( [index]=--with-cc-opt='-m64 -march=native -DTCP_FASTOPEN=23 -g -O3 -fstack-protector-strong -flto -fuse-ld=gold --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wimplicit-fallthrough=0 -Wno-error=date-time -D_FORTIFY_SOURCE=2' )
    NGX_RTMP="--add-module=/usr/local/src/nginx-rtmp-module "
else
    NGINX_CC_OPT=( [index]=--with-cc-opt='-m64 -march=native -DTCP_FASTOPEN=23 -g -O3 -fstack-protector-strong -flto -fuse-ld=gold --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wimplicit-fallthrough=0 -fcode-hoisting -Wp,-D_FORTIFY_SOURCE=2 -gsplit-dwarf' )
    NGX_RTMP=""
fi

if [ "$NAXSI" = "y" ]; then
    NGX_NAXSI="--add-module=/usr/local/src/naxsi/naxsi_src "
else
    NGX_NAXSI=""
fi


if [ "$PAGESPEED_RELEASE" = "1" ]; then
    NGX_PAGESPEED="--add-module=/usr/local/src/incubator-pagespeed-ngx-latest-beta "
    elif [ "$PAGESPEED_RELEASE" = "2" ]; then
    NGX_PAGESPEED="--add-module=/usr/local/src/incubator-pagespeed-ngx-latest-stable "
else
    NGX_PAGESPEED=""
fi


##################################
# Install dependencies
##################################

echo -ne '       Installing dependencies               [..]\r'
apt-get update >>/tmp/nginx-ee.log 2>&1
apt-get install -y git build-essential libtool automake autoconf zlib1g-dev \
libpcre3 libpcre3-dev libgd-dev libssl-dev libxslt1-dev libxml2-dev libgeoip-dev libjemalloc1 libjemalloc-dev \
libbz2-1.0 libreadline-dev libbz2-dev libbz2-ocaml libbz2-ocaml-dev software-properties-common sudo tar zlibc zlib1g zlib1g-dbg \
libcurl4-openssl-dev libgoogle-perftools-dev libperl-dev libpam0g-dev libbsd-dev zip unzip gnupg gnupg2 pigz libluajit-5.1-common \
libluajit-5.1-dev libmhash-dev libexpat-dev libgmp-dev autotools-dev bc checkinstall ccache curl debhelper dh-systemd libxml2 >>/tmp/nginx-ee.log 2>&1

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

if [ "$NGINX_FROM_SCRATCH" = "1" ]; then

    # clone custom nginx configuration
    git clone https://github.com/VirtuBox/nginx-config.git /etc/nginx

    # create nginx temp directory
    mkdir -p /var/lib/nginx/{body,fastcgi,proxy,scgi,uwsgi}
    # create nginx cache directory
    [ ! -d /var/cache/nginx ] && {
        mkdir -p /var/run/nginx-cache
    }
    [ ! -d /var/run/nginx-cache ] && {
        mkdir -p /var/run/nginx-cache
    }
    # set proper permissions
    chown -R www-data:root /var/lib/nginx/* /var/cache/nginx /var/run/nginx-cache
    # create websites directory
    mkdir -p /var/www/html

    {

        wget -O /var/www/html/index.nginx-debian.html https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/var/www/html/index.nginx-debian.html
        ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

        [ ! -f /lib/systemd/system/nginx.service ] && {
            wget -O /lib/systemd/system/nginx.service https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/etc/systemd/system/nginx.service
            systemctl enable nginx.service
        }

    } >>/tmp/nginx-ee.log 2>&1

fi

##################################
# Install gcc7 or gcc8 from PPA
##################################
# gcc7 for nginx stable on Ubuntu 16.04 LTS
# gcc8 for nginx mainline on Ubuntu 16.04 LTS & 18.04 LTS

# Checking lsb_release package
if [ ! -x /usr/bin/lsb_release ]; then
    sudo apt-get -y install lsb-release | sudo tee -a /tmp/nginx-ee.log 2>&1
fi

# install gcc-7
distro_version=$(lsb_release -sc)

{

    if [ "$distro_version" == "bionic" ] && [ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-bionic.list ]; then
        add-apt-repository -y ppa:jonathonf/gcc
        elif [ "$distro_version" == "xenial" ] && [ ! -f /etc/apt/sources.list.d/jonathonf-ubuntu-gcc-xenial.list ]; then
        add-apt-repository -y ppa:jonathonf/gcc
    fi

    apt-get update
    apt-get upgrade -y

} >>/tmp/nginx-ee.log 2>&1






if [ "$NGINX_RELEASE" == "1" ] && [ "$RTMP" != "y" ]; then
    if [  "$distro_version" == "bionic" ]; then
        echo -ne '       Installing gcc-8                       [..]\r'
        {
            apt-get install gcc-8 g++-8 -y
            update-alternatives --remove-all gcc
            update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 80 --slave /usr/bin/g++ g++ /usr/bin/g++-8
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

        elif [ "$distro_version" == "xenial" ]; then
        echo -ne '       Installing gcc-8                       [..]\r'
        {
            add-apt-repository -y ppa:jonathonf/gcc-8.1
            apt-get update
            apt-get install gcc-8 g++-8 -y
            update-alternatives --remove-all gcc
            update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 80 --slave /usr/bin/g++ g++ /usr/bin/g++-8
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
else
    if [ "$distro_version" == "xenial" ]; then

        echo -ne '       Installing gcc-7                       [..]\r'
        {
            add-apt-repository -y ppa:jonathonf/gcc-7.1
            apt-get update -y
            apt-get install gcc-7 g++-7 -y
            update-alternatives --remove-all gcc
            update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 80 --slave /usr/bin/g++ g++ /usr/bin/g++-7
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
rm -rf $DIR_SRC/{*.tar.gz,nginx-1.*,openssl,openssl-*,ngx_brotli,pcre,zlib,incubator-pagespeed-*,build_ngx_pagespeed.sh,install,ngx_http_redis*}

echo -ne '       Downloading additionals modules        [..]\r'

{
    # cache_purge module
    { [ -d $DIR_SRC/ngx_cache_purge ] && {
            git -C $DIR_SRC/ngx_cache_purge pull origin master
        } } || {
        git clone https://github.com/FRiCKLE/ngx_cache_purge.git
    }


    # memcached module
    { [ -d $DIR_SRC/memc-nginx-module ] && {
            git -C $DIR_SRC/memc-nginx-module pull origin master
        } } || {
        git clone https://github.com/openresty/memc-nginx-module.git
    }

    # devel kit
    { [ -d $DIR_SRC/ngx_devel_kit ] && {
            git -C $DIR_SRC/ngx_devel_kit pull origin master
        } } || {
        git clone https://github.com/simpl/ngx_devel_kit.git
    }
    # headers-more module
    { [ -d $DIR_SRC/headers-more-nginx-module ] && {
            git -C $DIR_SRC/headers-more-nginx-module pull origin master
        } } || {
        git clone https://github.com/openresty/headers-more-nginx-module.git
    }
    # echo module
    { [ -d $DIR_SRC/echo-nginx-module ] && {
            git -C $DIR_SRC/echo-nginx-module pull origin master
        } } || {
        git clone https://github.com/openresty/echo-nginx-module.git
    }
    # http_substitutions_filter module
    { [ -d $DIR_SRC/ngx_http_substitutions_filter_module ] && {
            git -C $DIR_SRC/ngx_http_substitutions_filter_module pull origin master
        } } || {
        git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git
    }
    # redis2 module
    { [ -d $DIR_SRC/redis2-nginx-module ] && {
            git -C $DIR_SRC/redis2-nginx-module pull origin master
        } } || {
        git clone https://github.com/openresty/redis2-nginx-module.git
    }
    # srcache module
    { [ -d $DIR_SRC/srcache-nginx-module ] && {
            git -C $DIR_SRC/srcache-nginx-module pull origin master
        } } || {
        git clone https://github.com/openresty/srcache-nginx-module.git
    }
    # set-misc module
    { [ -d $DIR_SRC/set-misc-nginx-module ] && {
            git -C $DIR_SRC/set-misc-nginx-module pull origin master
        } } || {
        git clone https://github.com/openresty/set-misc-nginx-module.git
    }
    # auth_pam module
    { [ -d $DIR_SRC/ngx_http_auth_pam_module ] && {
            git -C $DIR_SRC/ngx_http_auth_pam_module pull origin master
        } } || {
        git clone https://github.com/sto/ngx_http_auth_pam_module.git
    }
    # nginx-vts module
    { [ -d $DIR_SRC/nginx-module-vts ] && {
            git -C $DIR_SRC/nginx-module-vts pull origin master
        } } || {
        git clone https://github.com/vozlt/nginx-module-vts.git
    }
    # http redis module
    sudo curl -sL https://people.freebsd.org/~osa/ngx_http_redis-0.3.8.tar.gz | tar zxf - -C $DIR_SRC
    mv ngx_http_redis-0.3.8 ngx_http_redis
    if [ "$RTMP" = "y" ]; then
        {  [ -d $DIR_SRC/nginx-rtmp-module ] && {
                git -C $DIR_SRC/nginx-rtmp-module pull origin master
            } } || {
            git clone https://github.com/arut/nginx-rtmp-module.git
        }
    fi
    # ipscrub module
    { [ -d $DIR_SRC/ipscrubtmp ] && {
            git -C $DIR_SRC/ipscrubtmp pull origin master
        } } || {
        git clone https://github.com/masonicboom/ipscrub.git ipscrubtmp
    }

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
    sudo curl -sL http://zlib.net/zlib-1.2.11.tar.gz | tar zxf - -C $DIR_SRC
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

cd $DIR_SRC || exit 1

if [ ! -x /usr/bin/pcretest ]; then
    PCRE_VERSION=$(pcretest -C 2>&1 | grep version | awk -F " " '{print $3}')
    if [ "$PCRE_VERSION" != "8.42" ]; then
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
            ln -sfv ../../lib/"$(readlink /usr/lib/libpcre.so)" /usr/lib/libpcre.so
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
    fi
fi

##################################
# Download ngx_broti
##################################

cd $DIR_SRC || exit 1

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

cd $DIR_SRC || exit 1
{
    curl -sL https://www.openssl.org/source/openssl-1.1.1.tar.gz | tar zxf - -C $DIR_SRC
    mv openssl-1.1.1 openssl
    cd $DIR_SRC/openssl  || exit 1
} >> /tmp/nginx-ee.log 2>&1

{
    # apply openssl ciphers patch
    curl https://raw.githubusercontent.com/hakasenyang/openssl-patch/master/openssl-equal-1.1.1_ciphers.patch | patch -p1
    # apply patch from centminmod
    curl https://raw.githubusercontent.com/centminmod/centminmod/master/patches/openssl/OpenSSL-1.1.1-reset-tls1.3-ciphers-SSL_CTX_set_ssl_version.patch | patch -p1
    curl https://raw.githubusercontent.com/centminmod/centminmod/master/patches/openssl/OpenSSL-1.1.1-sni-fix-delay-sig-algs.patch | patch -p1
    curl https://raw.githubusercontent.com/centminmod/centminmod/123.09beta01/patches/openssl/OpenSSL-1.1.1-fix-ocsp-memleak.patch | patch -p1
    curl https://raw.githubusercontent.com/centminmod/centminmod/123.09beta01/patches/openssl/OpenSSL-1.1.1-safer-mem-cleanup.patch | patch -p1

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

cd $DIR_SRC || exit 1
if [ "$NAXSI" = "y" ]; then
    echo -ne '       Downloading naxsi                      [..]\r'
    {
        [ -d $DIR_SRC/naxsi ] && {
            rm -rf $DIR_SRC/naxsi
        }
        curl -sL https://github.com/nbs-system/naxsi/archive/$NAXSI_VER.tar.gz | tar zxf - -C $DIR_SRC
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

cd $DIR_SRC || exit 1
if [ "$PAGESPEED" = "y" ]; then
    echo -ne '       Downloading pagespeed                  [..]\r'

    {
        rm -rf
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

cd $DIR_SRC || exit  1
echo -ne '       Downloading nginx                      [..]\r'
[ -d $DIR_SRC/nginx ] && {
    rm -rf $DIR_SRC/nginx
}
{
    curl -sL http://nginx.org/download/nginx-${NGINX_VER}.tar.gz | tar zxf - -C $DIR_SRC
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

if [ "$NGINX_RELEASE" = "1" ]; then
    {
        curl -s https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.15.5%2B.patch | patch -p1
        curl -s https://raw.githubusercontent.com/centminmod/centminmod/123.09beta01/patches/cloudflare/nginx-1.15.3_http2-hpack.patch | patch -p1
        curl -s https://raw.githubusercontent.com/kn007/patch/master/nginx_auto_using_PRIORITIZE_CHACHA.patch | patch -p1
    } >>/tmp/nginx-ee.log 2>&1

else
    curl -s https://raw.githubusercontent.com/nginx-modules/ngx_http_tls_dyn_size/master/nginx__dynamic_tls_records_1.13.0%2B.patch | patch -p1  >>/tmp/nginx-ee.log 2>&1
fi


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

if [ "$distro_version" = "xenial" ] || [ "$distro_version" = "bionic" ]; then
if [ "$NGINX_RELEASE" = "1" ] && [ "$RTMP" != "y" ]; then
    export CC="/usr/bin/gcc-8"
    export CXX="/usr/bin/gc++-8"
else
    export CC="/usr/bin/gcc-7"
    export CXX="/usr/bin/gc++-7"
fi
fi

NGINX_BUILD_OPTIONS="--prefix=/usr/share \
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
--modules-path=/usr/share/nginx/modules"

NGINX_PLESK_BUILD="--prefix=/usr/share \
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
--modules-path=/usr/share/nginx/modules"

NGINX_INCLUDED_MODULES="--without-http_uwsgi_module \
--without-mail_imap_module \
--without-mail_pop3_module \
--without-mail_smtp_module \
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
--with-http_mp4_module \
--with-http_sub_module \
--with-file-aio \
--with-threads"

NGINX_THIRD_MODULES="--with-zlib=/usr/local/src/zlib \
--add-module=/usr/local/src/ngx_cache_purge \
--add-module=/usr/local/src/headers-more-nginx-module \
--add-module=/usr/local/src/memc-nginx-module \
--add-module=/usr/local/src/ngx_devel_kit \
--add-module=/usr/local/src/ngx_brotli \
--add-module=/usr/local/src/echo-nginx-module \
--add-module=/usr/local/src/ngx_http_substitutions_filter_module \
--add-module=/usr/local/src/redis2-nginx-module \
--add-module=/usr/local/src/srcache-nginx-module \
--add-module=/usr/local/src/set-misc-nginx-module \
--add-module=/usr/local/src/ngx_http_redis \
--add-module=/usr/local/src/ngx_http_auth_pam_module \
--add-module=/usr/local/src/nginx-module-vts \
--add-module=/usr/local/src/ipscrubtmp/ipscrub"

if [ "$NGINX_PLESK" = "0" ]; then

    ./configure \
    ${NGX_NAXSI} \
    "${NGINX_CC_OPT[@]}" \
    --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now' \
    ${NGINX_BUILD_OPTIONS} \
    --build='VirtuBox Nginx-ee' \
    ${NGINX_INCLUDED_MODULES} \
    ${NGINX_THIRD_MODULES} \
    ${NGX_HPACK}
    ${NGX_PAGESPEED} \
    ${NGX_RTMP} \
    --with-openssl=/usr/local/src/openssl \
    --with-openssl-opt='enable-ec_nistp_64_gcc_128 enable-tls1_3' \
    --sbin-path=/usr/sbin/nginx >>/tmp/nginx-ee.log 2>&1

else

    ./configure \
    ${NGX_NAXSI} \
    "${NGINX_CC_OPT[@]}" \
    --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,-z,now' \
    ${NGINX_PLESK_BUILD} \
    --build='VirtuBox Nginx-ee' \
    --user=nginx \
    --group=nginx \
    ${NGINX_INCLUDED_MODULES} \
    ${NGINX_THIRD_MODULES} \
    ${NGX_PAGESPEED} \
    ${NGX_RTMP} \
    --with-openssl=/usr/local/src/openssl \
    --with-openssl-opt='enable-ec_nistp_64_gcc_128 enable-tls1_3' \
    --with-zlib=/usr/local/src/zlib \
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

[ ! -f /etc/apt/preferences.d/nginx-block ] && {
    if [ "$NGINX_PLESK" = "1" ]; then
        {
            # block sw-nginx package updates from APT repository
            echo -e 'Package: sw-nginx*\nPin: release *\nPin-Priority: -1' > /etc/apt/preferences.d/nginx-block
            apt-mark unhold sw-nginx
        } >> /tmp/nginx-ee.log
    elif [ "$NGINX_EASYENGINE" = "1" ]; then
        # replace old TLS v1.3 ciphers suite
        {
            sed -i 's/TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-256-GCM-SHA384:TLS13-AES-128-GCM-SHA256/TLS13+AESGCM+AES128/' /etc/nginx/nginx.conf
            echo -e 'Package: nginx*\nPin: release *\nPin-Priority: -1' > /etc/apt/preferences.d/nginx-block
            apt-mark unhold nginx-ee nginx-common
        } >> /tmp/nginx-ee.log
        else
        {
        echo -e 'Package: nginx*\nPin: release *\nPin-Priority: -1' > /etc/apt/preferences.d/nginx-block
        apt-mark unhold nginx nginx-full nginx-common
        }
    fi
}

{
    systemctl unmask nginx.service
    systemctl enable nginx.service
    systemctl start nginx.service
    rm /etc/nginx/{*.default,*.dpkg-dist}
} > /dev/null 2>&1




echo -ne '       Checking nginx configuration           [..]\r'

# check if nginx -t do not return errors
VERIFY_NGINX_CONFIG=$(nginx -t 2>&1 | grep failed)
if [ -z "$VERIFY_NGINX_CONFIG" ]; then
    {
        systemctl stop nginx
        systemctl start nginx
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
