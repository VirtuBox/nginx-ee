#!/usr/bin/env bash
apt-get update -qq >/dev/null 2>&1
LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y >/dev/null 2>&1
rm -rf /etc/mysql /var/lib/mysql /etc/nginx
#apt-get install make libunwind-dev libgoogle-perftools-dev -y >/dev/null 2>&1
apt-get purge --option=Dpkg::options::=--force-all --assume-yes graphviz* redis* php* mysql* nginx* >/dev/null 2>&1
apt-get -qq autoremove --purge >/dev/null 2>&1
