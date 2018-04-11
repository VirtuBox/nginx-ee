# Nginx-EE 

Compile and install the latest nginx release with EasyEngine


![nginx-ee](https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-ee.png)


-----
## Features
* Update Nginx to the Latest mainline release 
* Additonal modules
* TLS v1.3 Support

-----

## Additional modules 

Nginx current release : **v1.13.12**

* ngx_cache_purge
* memcached_nginx_module
* headers-more-nginx-module
* ngx_coolkit
* ngx_brotli
* redis2-nginx-module
* srcache-nginx-module
* ngx_http_substitutions_filter_module
* nginx-dynamic-tls-records-patch_1.13.0+
* Openssl 1.1.1
* ngx_http_auth_pam_module
* ngx_pagespeed (optional)
* naxsi WAF (optional)
-----

## Compatibility

* Ubuntu 16.04 LTS
* Debian 8 Jessie 

----

## Requirements
* Nginx already installed by EasyEngine 

-----

## Usage

```
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```
-----

##  Nginx configuration 

* [Wiki](https://github.com/VirtuBox/nginx-ee/wiki/)

-----
## Roadmap
* add nginx configuration examples
* add nginx stable release

Published by <a href="https://virtubox.net" title="VirtuBox">VirtuBox</a>



