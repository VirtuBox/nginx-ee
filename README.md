<h1 align="center">
<br>
<img src="https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-ee-logo.png">
<br>
  Nginx-ee
  <br>
</h1>

<h4 align="center">
Automated Nginx compilation from sources with additional modules support
</h4>

---

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/4755fe17202f4a5c9df402c04c3f4048)](https://app.codacy.com/app/VirtuBox/nginx-ee?utm_source=github.com&utm_medium=referral&utm_content=VirtuBox/nginx-ee&utm_campaign=Badge_Grade_Dashboard)

<p align="center">
<a href="https://travis-ci.com/VirtuBox/nginx-ee"><img src="https://travis-ci.com/VirtuBox/nginx-ee.svg?branch=master" alt="build" /></a>
<img src="https://img.shields.io/github/license/VirtuBox/nginx-ee.svg" alt="MIT">
<img src="https://img.shields.io/github/stars/VirtuBox/nginx-ee.svg" alt="Stars">
<img src="https://img.shields.io/github/last-commit/virtubox/nginx-ee/master.svg?style=flat" alt="Commits">
<img src="https://img.shields.io/github/release/VirtuBox/nginx-ee.svg?style=flat" alt="GitHub release"></p>

<p align="center">
<a href="#features"> Features<a> •
<a href="#additional-third-party-modules"> Modules</a> •
<a href="#compatibility"> Compatibility</a> •
<a href="#usage"> Usage</a> •
<a href="https://github.com/VirtuBox/nginx-ee/wiki"> Wiki</a> •
<a href="#related"> Related</a> •
<a href="#credits"> Credits</a> •
<a href="#license"> License</a></p>

<p align="center"><img src="https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-ee.png" alt="Nginx-ee"></p>

---

## Features

* Compile the latest Nginx releases : stable or mainline
* Install Nginx or replace Nginx package previously installed
* Nginx built-in modules selection
* Nginx Third-party modules selection
* Dynamic modules support
* Brotli Support
* TLS v1.3 support (Final)
* OpenSSL (1.1.1b or 3.0.0-dev) or LibreSSL
* Cloudflare HPACK (for Mainline release only)
* Cloudflare zlib
* Automated nginx updates cronjob
* Compilation with GCC-7/8
* Security hardening and performance optimization enabled with proper GCC flags

---

## Additional Third-party modules

Nginx current mainline release : **v1.15.12**
Nginx current stable release : **v1.16.0**

* [ngx_cache_purge](https://github.com/FRiCKLE/ngx_cache_purge)
* [headers-more-nginx-module](https://github.com/openresty/headers-more-nginx-module)
* [ngx_brotli](https://github.com/eustas/ngx_brotli)
* [memc-nginx-module](https://github.com/openresty/memc-nginx-module.git)
* [ngx-devel-kit](https://github.com/simpl/ngx_devel_kit.git)
* [srcache-nginx-module](https://github.com/openresty/srcache-nginx-module)
* [ngx_http_substitutions_filter_module](https://github.com/yaoweibin/ngx_http_substitutions_filter_module)
* [nginx_dynamic_tls_records](https://github.com/nginx-modules/ngx_http_tls_dyn_size)
* [ipscrub](http://www.ipscrub.org/)
* [ngx_http_auth_pam_module](https://github.com/sto/ngx_http_auth_pam_module)
* [virtual-host-traffic-status](https://github.com/vozlt/nginx-module-vts)
* [Cloudflare zlib](https://github.com/cloudflare/zlib.git)
* [redis2-nginx-module](https://github.com/openresty/redis2-nginx-module.git)

For Nginx http_ssl_module :

* [OpenSSL](https://github.com/openssl/openssl)
* [LibreSSL](https://github.com/libressl-portable)

Optional modules :

* [ngx_pagespeed](https://github.com/apache/incubator-pagespeed-ngx)
* [naxsi WAF](https://github.com/nbs-system/naxsi)
* [nginx-rtmp-module](https://github.com/arut/nginx-rtmp-module)

---

## Compatibility

### Operating System

#### Recommended

* Ubuntu 18.04 LTS (Bionic)
* Ubuntu 16.04 LTS (Xenial)

#### Also compatible

* Debian 9 (Stretch)
* Debian 8 (Jessie)
* Raspbian (Stretch)

### Applications

#### LEMP Stack

* EasyEngine v3
* WordOps

#### Plesk

* 17.5.x
* 17.8.x
* 17.9.x

---

## Usage

### One-Step Automated Install

* mainline release
* without pagespeed
* without naxsi
* without rtmp

```bash
bash <(wget -O - vtb.cx/nginx-ee || curl -sL vtb.cx/nginx-ee)
```

### Alternative Install Method

```bash
git clone https://github.com/VirtuBox/nginx-ee
cd nginx-ee
sudo bash nginx-build.sh
```

### Interactive install

Interactive installation is available with arguments `-i` or `--interactive`

```bash
bash <(wget -O - vtb.cx/nginx-ee || curl -sL vtb.cx/nginx-ee) --interactive
```

### Custom installation

Example : Nginx stable release with pagespeed and naxsi

```bash
bash <(wget -O - vtb.cx/nginx-ee || curl -sL vtb.cx/nginx-ee) --stable --pagespeed --naxsi
```

#### Options available

Nginx build options :

* `--stable` : compile Nginx stable release
* `--full` : Naxsi + PageSpeed + RTMP
* `--dynamic` : Compile Nginx modules as dynamic modules

Optional third-party modules :

* `--pagespeed`: compile nginx with ngx_pagespeed latest-stable
* `--pagespeed-beta`: compile nginx with ngx_pagespeed latest-beta
* `--naxsi` : compile nginx with naxsi
* `--rtmp` : compile nginx with rtmp module
* `--libressl` : compile nginx with LibreSSL instead of OpenSSL
* `--openssl-dev` : compile nginx with OpenSSL 3.0.0-dev
* `--openssl-system` : compile nginx with OpenSSL system lib

Extras :

* `--cron` : setup daily cronjob to update nginx each time a new release is available

---

## Roadmap

* [x] Add choice between stable & mainline release
* [x] Add Nginx configuration examples
* [x] Add Cloudflare HPACK patch
* [x] Add support for servers without EasyEngine
* [x] Add non-interactive installation
* [x] Add automated update detection
* [x] Add support for Plesk servers
* [x] Add Nginx modules choice
* [x] Add support for Debian 9
* [ ] Add support for config.inc build configuration
* [x] Add openssl release choice
* [ ] Add more compilation presets
* [x] Add support for LibreSSL

---

## Related

* [Ubuntu-nginx-web-server](https://github.com/VirtuBox/ubuntu-nginx-web-server) : repository with all custom nginx configurations used by VirtuBox
* [WordOps](https://github.com/WordOps/WordOps)
* [Plesk-nginx-fastcgi-cache-template](https://github.com/VirtuBox/plesk-nginx-fascgi-cache-template) : Plesk Onyx custom hosting templates with fastcgi_cache support
* [Nginx-Cloudflare-real-ip](https://github.com/VirtuBox/nginx-cloudflare-real-ip) : Bash script to restore visitor real IP under Cloudflare with Nginx
* [Advanced Nginx Cheatsheet](https://github.com/VirtuBox/advanced-nginx-cheatsheet)

---

## Contributing

If you have any ideas, just open an issue and describe what you would like to add/change in Nginx-ee.

If you'd like to contribute, please fork the repository and make changes as you'd like. Pull requests are warmly welcome.

## Credits

* [centminmod](https://github.com/centminmod/centminmod) : Nginx, Nginx modules & various other patches
* [hakase](https://github.com/hakasenyang/openssl-patch) : OpenSSL-patch
* [Karl Chen](https://github.com/kn007/patch) : Nginx patches

## License

[MIT](https://github.com/VirtuBox/nginx-ee/blob/master/LICENSE) © <a href="https://virtubox.net" title="VirtuBox" target="_blank">VirtuBox</a>
