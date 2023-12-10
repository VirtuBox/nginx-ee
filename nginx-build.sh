#!/usr/bin/env bash
# -------------------------------------------------------------------------
#  Nginx-ee - Automated Nginx compilation from source
# -------------------------------------------------------------------------
# Website:       https://virtubox.net
# GitHub:        https://github.com/VirtuBox/nginx-ee
# Copyright (c) 2019-2020 VirtuBox <contact@virtubox.net>
# This script is licensed under M.I.T
# -------------------------------------------------------------------------
# Version 3.8.0 - 2023-05-08
# -------------------------------------------------------------------------

##################################
# Check requirements
##################################

# Check if user is root
[ "$(id -u)" != "0" ] && {
    echo "Error: You must be root or use sudo to run this script"
    exit 1
}

_help() {
    echo " -------------------------------------------------------------------- "
    echo "   Nginx-ee : automated Nginx compilation with additional modules  "
    echo " -------------------------------------------------------------------- "
    echo ""
    echo "Usage: ./nginx-ee <options> [modules]"
    echo "By default, Nginx-ee will compile the latest Nginx mainline release without Pagespeed, Naxsi or RTMP module"
    echo "  Options:"
    echo "       -h, --help ..... display this help"
    echo "       -i, --interactive ....... interactive installation"
    echo "       --stable ..... Nginx stable release"
    echo "       --full ..... Nginx mainline release with Nasxi and RTMP module"
    echo "       --dynamic ..... Compile Nginx modules as dynamic"
    echo "       --noconf ..... Compile Nginx without any configuring. Useful when you use devops tools like ansible."
    echo "  Modules:"
    echo "       --naxsi ..... Naxsi WAF module"
    echo "       --rtmp ..... RTMP video streaming module"
    echo "       --openssl-dev ..... Compile Nginx with OpenSSL 3.0.0-dev"
    echo "       --openssl-system ..... Compile Nginx with OpenSSL from system lib"
    echo "       --libressl ..... Compile Nginx with LibreSSL"
    echo ""
    return 0
}

##################################
# Use config.inc if available
##################################

if [ -f ./config.inc ]; then

    . ./config.inc

else

    ##################################
    # Parse script arguments
    ##################################

    while [ "$#" -gt 0 ]; do
        case "$1" in
        --full)
            NAXSI="y"
            RTMP="y"
            ;;
        --noconf)
            NOCONF="y"
            ;;
        --naxsi)
            NAXSI="y"
            ;;
        --libressl)
            LIBRESSL="y"
            ;;
        --rtmp)
            RTMP="y"
            ;;
        --latest | --mainline)
            NGINX_RELEASE="1"
            ;;
        --stable)
            NGINX_RELEASE="2"
            ;;
        -i | --interactive)
            INTERACTIVE_SETUP="1"
            ;;
        --dynamic)
            DYNAMIC_MODULES="y"
            ;;
        --cron | --cronjob)
            CRON_SETUP="y"
            ;;
        --travis)
            TRAVIS_BUILD="1"
            ;;
        -h | --help)
            _help
            exit 1
            ;;
        *) ;;
        esac
        shift
    done

fi

export DEBIAN_FRONTEND=noninteractive

# check if a command exist
command_exists() {
    command -v "$@" >/dev/null 2>&1
}

# updating packages list
[ -z "$TRAVIS_BUILD" ] && {
    if [ -f "/etc/apt/sources.list.d/nginx-ee.list" ]; then
        rm /etc/apt/sources.list.d/nginx-ee.list -f
    fi
    apt-get update -qq
}

# check if required packages are installed
required_packages="curl tar jq"
for package in $required_packages; do
    if ! command_exists "$package"; then
        apt-get install "$package" -qq >/dev/null 2>&1
    fi
done

# Checking if lsb_release is installed
if ! command_exists lsb_release; then
    apt-get -qq install lsb-release >/dev/null 2>&1
fi

##################################
# Variables
##################################

DIR_SRC="/usr/local/src"
NGINX_EE_VER=$(curl -m 5 --retry 3 -sL https://api.github.com/repos/VirtuBox/nginx-ee/releases/latest 2>&1 | jq -r '.tag_name')
NGINX_MAINLINE="$(curl -sL https://nginx.org/en/download.html 2>&1 | grep -E -o 'nginx\-[0-9.]+\.tar[.a-z]*' | awk -F "nginx-" '/.tar.gz$/ {print $2}' | sed -e 's|.tar.gz||g' | head -n 1 2>&1)"
NGINX_STABLE="$(curl -sL https://nginx.org/en/download.html 2>&1 | grep -E -o 'nginx\-[0-9.]+\.tar[.a-z]*' | awk -F "nginx-" '/.tar.gz$/ {print $2}' | sed -e 's|.tar.gz||g' | head -n 2 | grep 1.24 2>&1)"
LIBRESSL_VER="3.7.2"
if command_exists openssl; then
    OPENSSL_BIN_VER=$(openssl version)
    OPENSSL_VER=${OPENSSL_BIN_VER:0:15}
else
    OPENSSL_VER="From system"
fi
TLS13_CIPHERS="TLS13+AESGCM+AES256:TLS13+AESGCM+AES128:TLS13+CHACHA20:EECDH+CHACHA20:EECDH+AESGCM:EECDH+AES"
readonly OS_ARCH="$(uname -m)"
OS_DISTRO_FULL="$(lsb_release -ds)"
readonly DISTRO_ID="$(lsb_release -si)"
readonly DISTRO_CODENAME="$(lsb_release -sc)"

# Colors
CSI='\033['
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CEND="${CSI}0m"

##################################
# Initial check & cleanup
##################################

# clean previous install log

echo "" >/tmp/nginx-ee.log

# detect Plesk
[ -d /etc/psa ] && {
    PLESK_VALID="YES"
}

# detect easyengine
[ -f /var/lib/ee/ee.db ] && {
    EE_VALID="YES"
}

[ -f /var/lib/wo/dbase.db ] && {
    WO_VALID="YES"
}

[ -z "$(command -v nginx)" ] && {
    NGINX_FROM_SCRATCH="1"
}

##################################
# Installation menu
##################################

echo ""
echo "Welcome to the nginx-ee bash script ${NGINX_EE_VER}"
echo ""

# interactive
if [ "$INTERACTIVE_SETUP" = "1" ]; then
    clear
    echo ""
    echo "Do you want to compile the latest Nginx [1] Mainline v${NGINX_MAINLINE} or [2] Stable v${NGINX_STABLE} Release ?"
    while [[ "$NGINX_RELEASE" != "1" && "$NGINX_RELEASE" != "2" ]]; do
        echo -e "Select an option [1-2]: " && read -r NGINX_RELEASE
    done
    echo -e '\nDo you prefer to compile Nginx with OpenSSL [1] or LibreSSL [2] ? (y/n)'
    echo -e '  [1] OpenSSL'
    echo -e '  [2] LibreSSL\n'
    while [[ "$SSL_LIB_CHOICE" != "1" && "$SSL_LIB_CHOICE" != "2" ]]; do
        echo -e "Select an option [1-2]: " && read -r SSL_LIB_CHOICE
    done
    if [ "$SSL_LIB_CHOICE" = "1" ]; then
        OPENSSL_LIB=3
    else
        LIBRESSL="y"
    fi
    echo -e '\nDo you want NAXSI WAF (still experimental)? (y/n)'
    while [[ "$NAXSI" != "y" && "$NAXSI" != "n" ]]; do
        echo -e "Select an option [y/n]: " && read -r NAXSI
    done
    echo -e '\nDo you want RTMP streaming module (used for video streaming) ? (y/n)'
    while [[ "$RTMP" != "y" && "$RTMP" != "n" ]]; do
        echo -e "Select an option [y/n]: " && read -r RTMP
    done
    echo -e '\nDo you want to build modules as dynamic modules? (y/n)'
    while [[ "$DYNAMIC_MODULES" != "y" && "$DYNAMIC_MODULES" != "n" ]]; do
        echo -e "Select an option [y/n]: " && read -r DYNAMIC_MODULES
    done
    echo -e '\nDo you want to setup nginx-ee auto-update cronjob ? (y/n)'
    while [[ "$CRON_SETUP" != "y" && "$CRON_SETUP" != "n" ]]; do
        echo -e "Select an option [y/n]: " && read -r CRON_SETUP
    done
    echo ""
fi

##################################
# Set nginx release and HPACK
##################################

if [ "$NGINX_RELEASE" = "2" ]; then
    NGINX_VER="$NGINX_STABLE"
    NGX_HPACK="--with-http_v2_hpack_enc"
else
    NGINX_VER="$NGINX_MAINLINE"
    NGX_HPACK=""
fi

##################################
# Set RTMP module
##################################

if [ "$RTMP" = "y" ]; then
    NGX_RTMP="--add-module=../nginx-rtmp-module "
    RTMP_VALID="YES"
else
    NGX_RTMP=""
    RTMP_VALID="NO"
fi

##################################
# Set Naxsi module
##################################

if [ "$NAXSI" = "y" ]; then
    NGX_NAXSI="--add-module=../naxsi/naxsi_src "
    NAXSI_VALID="YES"
else
    NGX_NAXSI=""
    NAXSI_VALID="NO"
fi

##################################
# Set OPENSSL/LIBRESSL lib
##################################

if [ "$LIBRESSL" = "y" ]; then
    NGX_SSL_LIB="--with-openssl=../libressl"
    LIBRESSL_VALID="YES"
    OPENSSL_OPT=""
else
    if [ "$OS_ARCH" = 'x86_64' ]; then
        if [ "$DISTRO_ID" = "Ubuntu" ]; then
            OPENSSL_OPT="enable-ec_nistp_64_gcc_128 enable-tls1_3 no-ssl3-method -march=native -ljemalloc"
        else
            OPENSSL_OPT="enable-tls1_3"
        fi
    fi
    NGX_SSL_LIB=""
    OPENSSL_VALID="from system"
    LIBSSL_DEV="libssl-dev"

fi

##################################
# Set Pagespeed module
##################################

NGX_PAGESPEED=""
PAGESPEED_VALID="NO"

##################################
# Set Plesk configuration
##################################

if [ "$PLESK_VALID" = "YES" ]; then
    NGX_USER="--user=nginx --group=nginx"
else
    NGX_USER=""
fi

if [ "$DYNAMIC_MODULES" = "y" ]; then
    DYNAMIC_MODULES_VALID="YES"
else
    DYNAMIC_MODULES_VALID="NO"
fi

##################################
# Display Compilation Summary
##################################

echo ""
echo -e "${CGREEN}##################################${CEND}"
echo " Compilation summary "
echo -e "${CGREEN}##################################${CEND}"
echo ""
echo " Detected OS : $OS_DISTRO_FULL"
echo " Detected Arch : $OS_ARCH"
echo ""
echo -e "  - Nginx release : $NGINX_VER"
[ -n "$OPENSSL_VALID" ] && {
    echo -e "  - OPENSSL : $OPENSSL_VER"
}
[ -n "$LIBRESSL_VALID" ] && {
    echo -e "  - LIBRESSL : $LIBRESSL_VALID"
}
echo "  - Dynamic modules $DYNAMIC_MODULES_VALID"
echo "  - Naxsi : $NAXSI_VALID"
echo "  - RTMP : $RTMP_VALID"
[ -n "$EE_VALID" ] && {
    echo "  - EasyEngine : $EE_VALID"
}
[ -n "$WO_VALID" ] && {
    echo "  - WordOps : $WO_VALID"
}
[ -n "$PLESK_VALID" ] && {
    echo "  - Plesk : $PLESK_VALID"
}
echo ""

##################################
# Install dependencies
##################################

_gitget() {
    REPO="$1"
    repodir=$(echo "$REPO" | awk -F "/" '{print $2}')
    if [ -d "/usr/local/src/${repodir}/.git" ]; then
        git -C "/usr/local/src/${repodir}" pull &
    else
        if [ -d "/usr/local/src/${repodir}" ]; then
            rm -rf "/usr/local/src/${repodir}"
        fi
        git clone --depth 1 "https://github.com/${REPO}.git" "/usr/local/src/${repodir}" &

    fi
}

_install_dependencies() {
    echo -ne '       Installing dependencies                [..]\r'
    if {
        apt-get -o Dpkg::Options::="--force-confmiss" -o Dpkg::Options::="--force-confold" -y install \
            git build-essential libtool automake autoconf \
            libgd-dev dpkg-dev libgeoip-dev libjemalloc-dev \
            libbz2-1.0 libreadline-dev libbz2-dev libbz2-ocaml libbz2-ocaml-dev software-properties-common tar \
            libgoogle-perftools-dev perl libperl-dev libpam0g-dev libbsd-dev gnupg gnupg2 \
            libgmp-dev autotools-dev libxml2-dev libpcre3-dev uuid-dev libbrotli-dev libpcre2-dev "$LIBSSL_DEV"
    } >>/tmp/nginx-ee.log 2>&1; then
        echo -ne "       Installing dependencies                [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "        Installing dependencies              [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1

    fi
}

##################################
# Setup Nginx from scratch
##################################

_nginx_from_scratch_setup() {

    echo -ne '       Setting Up Nginx configurations        [..]\r'
    if {
        # clone custom nginx configuration
        [ ! -d /etc/nginx ] && {
            git clone --depth 50 https://github.com/VirtuBox/nginx-config.git /etc/nginx
        } >>/tmp/nginx-ee.log 2>&1

        # create nginx temp directory
        mkdir -p /var/lib/nginx/{body,fastcgi,proxy,scgi,uwsgi}
        # create nginx cache directory
        [ ! -d /var/cache/nginx ] && {
            mkdir -p /var/cache/nginx
        }
        [ ! -d /var/run/nginx-cache ] && {
            mkdir -p /var/run/nginx-cache
        }
        [ ! -d /var/log/nginx ] && {
            mkdir -p /var/log/nginx
            chmod 640 /var/log/nginx
            chown -R www-data:adm /var/log/nginx
        }

        # set proper permissions
        chown -R www-data:root /var/lib/nginx /var/cache/nginx /var/run/nginx-cache

        # create websites directory
        [ ! -d /var/www/html ] && {
            mkdir -p /var/www/html
        }

        {
            # download default nginx page
            wget -O /var/www/html/index.nginx-debian.html https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/var/www/html/index.nginx-debian.html
            mkdir -p /etc/nginx/sites-enabled
            ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
            # download nginx systemd service
            [ ! -f /lib/systemd/system/nginx.service ] && {
                wget -O /lib/systemd/system/nginx.service https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/etc/systemd/system/nginx.service
                systemctl enable nginx.service
            }

            # download logrotate configuration
            wget -O /etc/logrotate.d/nginx https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/etc/logrotate.d/nginx

        } >>/tmp/nginx-ee.log 2>&1

    }; then
        echo -ne "       Setting Up Nginx configurations        [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Setting Up Nginx configurations        [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

}

##################################
# Dynamic modules
##################################

_dynamic_setup() {
    if [ -d /usr/share/nginx/modules ]; then
        rm -rf /usr/share/nginx/modules/*.old
        mkdir -p /etc/nginx/{modules.available.d,modules.conf.d}
        rm -rf /etc/nginx/modules.conf.d/*
        modules_list=$(basename -a /usr/share/nginx/modules/*)
        for module in $modules_list; do
            echo "load_module /usr/share/nginx/modules/${module};" >"/etc/nginx/modules.available.d/${module%.so}.load"
            ln -s "/etc/nginx/modules.available.d/${module%.so}.load" "/etc/nginx/modules.conf.d/${module%.so}.conf"
        done
    fi
}

##################################
# Install gcc7 or gcc8 from PPA
##################################
# gcc7 if Nginx is compiled with RTMP module
# otherwise gcc8 is used

_gcc_setup() {
    echo -ne '       Installing gcc                         [..]\r'
    if {
        echo "### installing gcc ###"
        apt-get install gcc g++ -y
    } >>/dev/null 2>&1; then
        echo -ne "       Installing gcc                         [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "        Installing gcc                        [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi
}

##################################
# Install ffmpeg for rtmp module
##################################

_rtmp_setup() {
    echo -ne '       Installing FFMPEG for RTMP module      [..]\r'
    if {
        apt-get install ffmpeg -y
    } >>/dev/null 2>&1; then
        echo -ne "       Installing FFMPEG for RMTP module      [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Installing FFMPEG for RMTP module      [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi
}

##################################
# Cleanup modules
##################################

_cleanup_modules() {

    cd "$DIR_SRC" || exit 1
    rm -rf /usr/local/src/{*.tar.gz,nginx,nginx-1.*,pcre,zlib,incubator-pagespeed-*,build_ngx_pagespeed.sh,install,ngx_http_redis,naxsi}

}

##################################
# Download additional modules
##################################

_download_modules() {

    echo -ne '       Downloading additionals modules        [..]\r'
    if {
        echo "### downloading additionals modules ###"
        MODULES='FRiCKLE/ngx_cache_purge openresty/memc-nginx-module
        simpl/ngx_devel_kit openresty/headers-more-nginx-module
        openresty/echo-nginx-module yaoweibin/ngx_http_substitutions_filter_module
        openresty/redis2-nginx-module openresty/srcache-nginx-module
        openresty/set-misc-nginx-module sto/ngx_http_auth_pam_module
        vozlt/nginx-module-vts centminmod/ngx_http_redis'
        for MODULE in $MODULES; do
            _gitget "$MODULE"
        done
        if [ "$RTMP" = "y" ]; then
            { [ -d "$DIR_SRC/nginx-rtmp-module" ] && {
                git -C "$DIR_SRC/nginx-rtmp-module" pull &
            } } || {
                git clone --depth=1 https://github.com/arut/nginx-rtmp-module.git &
            }
        fi

        # ipscrub module
        { [ -d "$DIR_SRC/ipscrubtmp" ] && {
            git -C "$DIR_SRC/ipscrubtmp" pull origin master &
        } } || {
            git clone --depth=1 https://github.com/masonicboom/ipscrub.git ipscrubtmp &
        }
        wait
        echo "### additionals modules downloaded ###"
    } >>/tmp/nginx-ee.log 2>&1; then
        echo -ne "       Downloading additionals modules        [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "        Downloading additionals modules      [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

}

##################################
# Download zlib
##################################

_download_zlib() {

    echo -ne '       Downloading zlib                       [..]\r'

    if {
        cd "$DIR_SRC" || exit 1
        if [ "$OS_ARCH" = 'x86_64' ]; then
            { [ -d /usr/local/src/zlib-cf ] && {
                echo "### git pull zlib-cf ###"
                git -c /usr/local/src/zlib-cf pull
            }; } || {
                echo "### cloning zlib-cf ###"
                git clone --depth=1 https://github.com/cloudflare/zlib.git -b gcc.amd64 /usr/local/src/zlib-cf
            }
            cd /usr/local/src/zlib-cf || exit 1
            echo "### make distclean ###"
            make -f Makefile.in distclean
            echo "### configure zlib-cf ###"
            ./configure --prefix=/usr/local/zlib-cf
        else
            echo "### downloading zlib 1.2.13 ###"
            rm -rf zlib
            curl -sL http://zlib.net/zlib-1.2.13.tar.gz | /bin/tar zxf - -C "$DIR_SRC"
            mv zlib-1.2.13 zlib
        fi

    } >>/tmp/nginx-ee.log 2>&1; then
        echo -ne "       Downloading zlib                       [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Downloading zlib                       [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

}

##################################
# Download ngx_broti
##################################

_download_brotli() {

    cd "$DIR_SRC" || exit 1
    if {
        echo -ne '       Downloading brotli                     [..]\r'
        {
            rm /usr/local/src/ngx_brotli -rf
            git clone --recursive --depth=1 https://github.com/google/ngx_brotli /usr/local/src/ngx_brotli -q
            cd /usr/local/src/ngx_brotli || exit 1
            git submodule update --init
        } >>/tmp/nginx-ee.log 2>&1

    }; then
        echo -ne "       Downloading brotli                     [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Downloading brotli      [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

}

##################################
# Download and patch OpenSSL
##################################

_download_openssl_dev() {

    cd "$DIR_SRC" || exit 1
    if {
        echo -ne '       Downloading openssl                    [..]\r'

        {
            if [ -d /usr/local/src/openssl ]; then
                if [ ! -d /usr/local/src/openssl/.git ]; then
                    echo "### removing openssl extracted archive ###"
                    rm -rf /usr/local/src/openssl
                    echo "### cloning openssl ###"
                    git clone --depth=50 https://github.com/openssl/openssl.git /usr/local/src/openssl
                    cd /usr/local/src/openssl || exit 1
                    echo "### git checkout commit ###"
                    #git checkout $OPENSSL_COMMIT
                else
                    cd /usr/local/src/openssl || exit 1
                    echo "### reset openssl to master and clean patches ###"
                    git fetch --all
                    git reset --hard origin/master
                    git clean -f
                    #git checkout $OPENSSL_COMMIT
                fi
            else
                echo "### cloning openssl ###"
                git clone --depth=50 https://github.com/openssl/openssl.git /usr/local/src/openssl
                cd /usr/local/src/openssl || exit 1
                echo "### git checkout commit ###"
                #git checkout $OPENSSL_COMMIT
            fi
        } >>/tmp/nginx-ee.log 2>&1

        {
            if [ -d /usr/local/src/openssl-patch/.git ]; then
                cd /usr/local/src/openssl-patch || exit 1
                git pull origin master
            else
                git clone --depth=50 https://github.com/VirtuBox/openssl-patch.git /usr/local/src/openssl-patch
            fi
            cd /usr/local/src/openssl || exit 1
            # apply openssl ciphers patch
            echo "### openssl ciphers patch ###"
            #patch -p1 <../openssl-patch/openssl-equal-3.0.0-dev_ciphers.patch
        } >>/tmp/nginx-ee.log 2>&1

    }; then
        echo -ne "       Downloading openssl                    [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Downloading openssl      [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

}

##################################
# Download LibreSSL
##################################

_download_libressl() {

    cd "$DIR_SRC" || exit 1
    if {
        echo -ne '       Downloading LibreSSL                   [..]\r'

        {
            rm -rf /usr/local/src/libressl
            curl -sL http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VER}.tar.gz | /bin/tar xzf - -C "$DIR_SRC"
            mv /usr/local/src/libressl-${LIBRESSL_VER} /usr/local/src/libressl
        } >>/tmp/nginx-ee.log 2>&1

    }; then
        echo -ne "       Downloading LibreSSL                   [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Downloading LibreSSL      [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

}

##################################
# Download Naxsi
##################################

_download_naxsi() {

    cd "$DIR_SRC" || exit 1
    if {
        echo -ne '       Downloading naxsi                      [..]\r'
        {

            git clone --depth=50 --recurse-submodules https://github.com/wargio/naxsi.git /usr/local/src/naxsi -q

            if [ "$NOCONF" != "y" ]; then
                cp -f /usr/local/src/naxsi/naxsi_rules/naxsi_core.rules /etc/nginx/naxsi_core.rules
            fi

        } >>/tmp/nginx-ee.log 2>&1

    }; then
        echo -ne "       Downloading naxsi                      [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Downloading naxsi      [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

}

##################################
# Download Nginx
##################################

_download_nginx() {

    cd "$DIR_SRC" || exit 1
    if {
        echo -ne '       Downloading nginx                      [..]\r'

        {
            rm -rf /usr/local/src/nginx
            curl -sL "http://nginx.org/download/nginx-${NGINX_VER}.tar.gz" | /bin/tar xzf - -C "$DIR_SRC"
            mv "/usr/local/src/nginx-${NGINX_VER}" /usr/local/src/nginx
        } >>/tmp/nginx-ee.log 2>&1

    }; then
        echo -ne "       Downloading nginx                      [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Downloading nginx      [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

}

##################################
# Apply Nginx patches
##################################

_patch_nginx() {

    cd /usr/local/src/nginx || exit 1
    if {
        echo -ne '       Applying nginx patches                 [..]\r'

        {
            if [ "$NGINX_RELEASE" = "2" ]; then
                curl -sL https://raw.githubusercontent.com/kn007/patch/master/nginx_for_1.23.4.patch | patch -p1
            else
                curl -sL https://raw.githubusercontent.com/kn007/patch/master/nginx_dynamic_tls_records.patch | patch -p1
            fi
            #curl -sL https://raw.githubusercontent.com/kn007/patch/master/nginx_auto_using_PRIORITIZE_CHACHA.patch | patch -p1
        } >>/tmp/nginx-ee.log 2>&1

    }; then
        echo -ne "       Applying nginx patches                 [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Applying nginx patches                 [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

}

##################################
# Configure Nginx
##################################

_configure_nginx() {
    local DEB_CFLAGS
    local DEB_LFLAGS
    DEB_CFLAGS="$(dpkg-buildflags --get CPPFLAGS) -Wno-error=date-time"
    DEB_LFLAGS="$(dpkg-buildflags --get LDFLAGS)"

    if {
        echo -ne '       Configuring nginx build                [..]\r'

        # main configuration
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

        # built-in modules
        if [ -z "$OVERRIDE_NGINX_MODULES" ]; then
            NGINX_INCLUDED_MODULES="--with-http_stub_status_module \
        --with-http_realip_module \
        --with-http_auth_request_module \
        --with-http_addition_module \
        --with-http_gzip_static_module \
        --with-http_gunzip_module \
        --with-http_mp4_module \
        --with-http_sub_module"
        else
            NGINX_INCLUDED_MODULES="$OVERRIDE_NGINX_MODULES"
        fi

        # third party modules
        if [ -z "$OVERRIDE_NGINX_ADDITIONAL_MODULES" ]; then
            if [ "$DYNAMIC_MODULES" = "y" ]; then
                NGINX_THIRD_MODULES="--with-compat \
         --add-module=../ngx_http_substitutions_filter_module \
        --add-dynamic-module=../srcache-nginx-module \
        --add-dynamic-module=../redis2-nginx-module \
        --add-dynamic-module=../memc-nginx-module \
        --add-module=../ngx_devel_kit \
        --add-module=../ngx_http_redis \
        --add-module=../set-misc-nginx-module \
        --add-dynamic-module=../ngx_http_auth_pam_module \
        --add-module=../nginx-module-vts \
        --add-dynamic-module=../ipscrubtmp/ipscrub"
            else
                NGINX_THIRD_MODULES="--add-module=../ngx_http_substitutions_filter_module \
        --add-module=../srcache-nginx-module \
        --add-module=../redis2-nginx-module \
        --add-module=../ngx_http_redis \
        --add-module=../memc-nginx-module \
        --add-module=../ngx_devel_kit \
        --add-module=../set-misc-nginx-module \
        --add-module=../ngx_http_auth_pam_module \
        --add-module=../nginx-module-vts \
        --add-module=../ipscrubtmp/ipscrub"
            fi
        else
            NGINX_THIRD_MODULES="$OVERRIDE_NGINX_ADDITIONAL_MODULES"
        fi

        if [ "$OS_ARCH" = 'x86_64' ]; then
            if [ "$DISTRO_ID" = "Ubuntu" ]; then
                DEB_CFLAGS='-m64 -march=native -mtune=native -DTCP_FASTOPEN=23 -g -O3 -fstack-protector-strong -flto -ffat-lto-objects -fuse-ld=gold --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wimplicit-fallthrough=0 -fcode-hoisting -Wp,-D_FORTIFY_SOURCE=2 -gsplit-dwarf'
                DEB_LFLAGS='-lrt -ljemalloc -Wl,-z,relro -Wl,-z,now -fPIC -flto -ffat-lto-objects'
            fi
            ZLIB_PATH='../zlib-cf'
        else
            ZLIB_PATH='../zlib'
        fi
        bash -c "./configure \
                    ${NGX_NAXSI} \
                    --with-cc-opt='$DEB_CFLAGS' \
                    --with-ld-opt='$DEB_LFLAGS' \
                    $NGINX_BUILD_OPTIONS \
                    --build='VirtuBox Nginx-ee' \
                    $NGX_USER \
                    --with-file-aio \
                    --with-threads \
                    $NGX_HPACK \
                    --with-http_v2_module \
                    --with-http_ssl_module \
                    --with-pcre-jit \
                    $NGINX_INCLUDED_MODULES \
                    $NGINX_THIRD_MODULES \
                    $NGX_RTMP \
                    --add-module=../echo-nginx-module \
                    --add-module=../headers-more-nginx-module \
                    --add-module=../ngx_cache_purge \
                    --add-module=../ngx_brotli \
                    --with-zlib=$ZLIB_PATH \
                    $NGX_SSL_LIB \
                    --with-openssl-opt='$OPENSSL_OPT' \
                    --sbin-path=/usr/sbin/nginx >> /tmp/nginx-ee.log 2>&1;"

    }; then
        echo -ne "       Configuring nginx build                [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Configuring nginx build                [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

}

##################################
# Compile Nginx
##################################

_compile_nginx() {
    if {
        echo -ne '       Compiling nginx                        [..]\r'

        {
            # compile Nginx
            make -j "$(nproc)"
            # Strip debug symbols
            strip --strip-unneeded /usr/local/src/nginx/objs/nginx
            if [ "$DYNAMIC_MODULES" = "y" ]; then
                strip --strip-unneeded /usr/local/src/nginx/objs/*.so
            fi
            # install Nginx
            make install

        } >>/tmp/nginx-ee.log 2>&1
    }; then
        echo -ne "       Compiling nginx                        [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Compiling nginx                        [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

}

##################################
# Perform final tasks
##################################

_updating_nginx_manual() {

    echo -ne '       Updating Nginx manual                  [..]\r'
    if {
        # update nginx manual
        [ -f /usr/share/man/man8/nginx.8.gz ] && {
            rm /usr/share/man/man8/nginx.8.gz
        }

        {
            cp -f ${DIR_SRC}/nginx/man/nginx.8 /usr/share/man/man8
            gzip /usr/share/man/man8/nginx.8

        } >>/tmp/nginx-ee.log

        # update mime.types
        cp -f ${DIR_SRC}/nginx/conf/mime.types /etc/nginx/mime.types

    }; then
        echo -ne "       Updating Nginx manual                  [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Updating Nginx manual                  [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

}

_cron_setup() {
    echo -ne '       Installing Nginx-ee Cronjob            [..]\r'
    if {
        wget -O /etc/cron.daily/nginx-ee https://raw.githubusercontent.com/VirtuBox/nginx-ee/develop/etc/cron.daily/nginx-ee >>/tmp/nginx-ee.log
        chmod +x /etc/cron.daily/nginx-ee

    }; then
        echo -ne "       Installing Nginx-ee Cronjob            [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Installing Nginx-ee Cronjob            [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

}

_cron_update() {
    if [ -f /etc/cron.daily/nginx-ee ]; then
        wget -O /etc/cron.daily/nginx-ee https://raw.githubusercontent.com/VirtuBox/nginx-ee/develop/etc/cron.daily/nginx-ee >>/tmp/nginx-ee.log
        chmod +x /etc/cron.daily/nginx-ee
    fi
}

_final_tasks() {

    echo -ne '       Performing final steps                 [..]\r'
    if {
        # block Nginx package update from APT repository
        if [ "$PLESK_VALID" = "YES" ]; then
            {
                # update nginx ciphers_suites
                # sed -i "s/ssl_ciphers\ \(\"\|.\|'\)\(.*\)\(\"\|.\|'\);/ssl_ciphers \"$TLS13_CIPHERS\";/" /etc/nginx/conf.d/ssl.conf
                # update nginx ssl_protocols
                # sed -i "s/ssl_protocols\ \(.*\);/ssl_protocols TLSv1.2 TLSv1.3;/" /etc/nginx/conf.d/ssl.conf
                # block sw-nginx package updates from APT repository
                echo -e 'Package: sw-nginx*\nPin: release *\nPin-Priority: -1' >/etc/apt/preferences.d/nginx-block
                apt-mark hold sw-nginx
            } >>/tmp/nginx-ee.log
        elif [ "$EE_VALID" = "YES" ]; then
            {
                # update nginx ssl_protocols
                sed -i "s/ssl_protocols\ \(.*\);/ssl_protocols TLSv1.2 TLSv1.3;/" /etc/nginx/nginx.conf
                # update nginx ciphers_suites
                sed -i "s/ssl_ciphers\ \(\"\|'\)\(.*\)\(\"\|'\)/ssl_ciphers \"$TLS13_CIPHERS\"/" /etc/nginx/nginx.conf
                # block nginx package updates from APT repository
                echo -e 'Package: nginx*\nPin: release *\nPin-Priority: -1' >/etc/apt/preferences.d/nginx-block
                apt-mark hold nginx-ee nginx-common nginx-custom
            } >>/tmp/nginx-ee.log
        elif [ "$WO_VALID" = "YES" ]; then
            {
                # update nginx ssl_protocols
                # sed -i "s/ssl_protocols\ \(.*\);/ssl_protocols TLSv1.2 TLSv1.3;/" /etc/nginx/nginx.conf
                # update nginx ciphers_suites
                # sed -i "s/ssl_ciphers\ \(\"\|.\|'\)\(.*\)\(\"\|.\|'\);/ssl_ciphers \"$TLS13_CIPHERS\";/" /etc/nginx/nginx.conf
                # block nginx package updates from APT repository
                echo -e 'Package: nginx*\nPin: release *\nPin-Priority: -1' >/etc/apt/preferences.d/nginx-block
                CHECK_NGINX_WO=$(dpkg --list | grep nginx-wo)
                if [ -n "$CHECK_NGINX_WO" ]; then
                    apt-mark hold nginx-wo nginx-common nginx-custom
                else
                    apt-mark hold nginx-ee nginx-common nginx-custom
                fi
            } >>/tmp/nginx-ee.log 2>&1
        fi

        if [ "$NOCONF" != "y" ]; then
            {
                # enable nginx service
                systemctl unmask nginx.service
                systemctl enable nginx.service
                systemctl start nginx.service
                # remove default configuration
                rm -f /etc/nginx/{*.default,*.dpkg-dist}
            } >/dev/null 2>&1
        fi

    }; then
        echo -ne "       Performing final steps                 [${CGREEN}OK${CEND}]\\r"
        echo -ne '\n'
    else
        echo -e "       Performing final steps                 [${CRED}FAIL${CEND}]"
        echo -e '\n      Please look at /tmp/nginx-ee.log\n'
        exit 1
    fi

    echo -ne '       Checking nginx configuration           [..]\r'

    if [ "$NOCONF" != "y" ]; then
        # check if nginx -t do not return errors
        VERIFY_NGINX_CONFIG=$(nginx -t 2>&1 | grep failed)
        if [ -z "$VERIFY_NGINX_CONFIG" ]; then
            {
                systemctl stop nginx
                systemctl start nginx
            } >>/tmp/nginx-ee.log 2>&1
            echo -ne "       Checking nginx configuration           [${CGREEN}OK${CEND}]\\r"
            echo ""
            echo -e "       ${CGREEN}Nginx-ee was compiled successfully !${CEND}"
            echo -e '\n       Installation log : /tmp/nginx-ee.log\n'
        else
            echo -e "       Checking nginx configuration           [${CRED}FAIL${CEND}]"
            echo -e "       Nginx-ee was compiled successfully but there is an error in your nginx configuration"
            echo -e '\nPlease look at /tmp/nginx-ee.log or use the command nginx -t to find the issue\n'
        fi
    else
        echo -e "       ${CGREEN}Nginx-ee was compiled successfully !${CEND}"
        echo -e '\nAs you requested not to configure it, you must do it manually or using your favourite devops tools.\n'
    fi

}

##################################
# Main Setup
##################################

_install_dependencies
if [ "$NGINX_FROM_SCRATCH" = "1" ]; then
    if [ "$NOCONF" != "y" ]; then
        _nginx_from_scratch_setup
    fi
fi
_gcc_setup
if [ "$RTMP" = "y" ]; then
    _rtmp_setup
fi
_cleanup_modules
_download_modules
_download_zlib
_download_brotli
if [ "$NAXSI" = "y" ]; then
    _download_naxsi
fi
if [ "$LIBRESSL" = "y" ]; then
    _download_libressl
else
    if [ "$OPENSSL_LIB" = "2" ]; then
        _download_openssl_dev
    elif [ "$OPENSSL_LIB" = "3" ]; then
        sleep 1
    else
        sleep 1
    fi
fi
_download_nginx
_patch_nginx
_configure_nginx
_compile_nginx
_updating_nginx_manual
_cron_update
if [ "$CRON_SETUP" = "y" ]; then
    _cron_setup
fi
if [ "$DYNAMIC_MODULES" = "y" ]; then
    if [ "$NOCONF" != "y" ]; then
        _dynamic_setup
    fi
fi
_final_tasks
echo "Give Nginx-ee a GitHub star : https://github.com/VirtuBox/nginx-ee"
