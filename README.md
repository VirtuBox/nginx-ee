# Nginx-EE

Compile and install the latest nginx releases with EasyEngine

![nginx-ee](https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-ee.png)

## nginx-ee [Github page](https://virtubox.github.io/nginx-ee/) now available

---

## Features

* Compile the latest Nginx Mainline or Stable Release
* Additonal modules
* TLS v1.3 draft28

---

## Additional modules

Nginx current mainline release : **v1.15.2**  
Nginx current stable release : **v1.14.0**

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
* [ipscrub](http://www.ipscrub.org/)
* ngx_http_auth_pam_module
* [virtual-host-traffic-status](https://github.com/vozlt/nginx-module-vts)

optional modules :

* ngx_pagespeed
* naxsi WAF
* [nginx-rtmp-module](https://github.com/arut/nginx-rtmp-module)

---

## Compatibility

* Ubuntu 16.04 LTS (Xenial)
* Ubuntu 18.04 LTS (Bionic)
* Debian 8 Jessie

---

## Requirements

* Nginx already installed with EasyEngine

---

## Usage

```bash
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```

---

## Nginx configuration

* [Wiki](https://github.com/VirtuBox/nginx-ee/wiki/)

---

## Roadmap

* add nginx configuration examples

## Credits & Licence

* [ipscrub nginx module](http://ipscrub.org/)

Published & maintained by <a href="https://virtubox.net" title="VirtuBox">VirtuBox</a>