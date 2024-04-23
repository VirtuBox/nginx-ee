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

<p align="center">
<a href="https://travis-ci.org/VirtuBox/nginx-ee"><img src="https://travis-ci.com/VirtuBox/nginx-ee.svg?branch=master" alt="build" /></a>
<img src="https://img.shields.io/github/license/VirtuBox/nginx-ee.svg" alt="MIT">
<img src="https://img.shields.io/github/stars/VirtuBox/nginx-ee.svg" alt="Stars">
<img src="https://img.shields.io/github/last-commit/virtubox/nginx-ee/master.svg?style=flat" alt="Commits">
<br>
<img src="https://img.shields.io/github/release/VirtuBox/nginx-ee.svg?style=flat" alt="GitHub release">
<a href="https://www.codacy.com/app/VirtuBox/nginx-ee?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=VirtuBox/nginx-ee&amp;utm_campaign=Badge_Grade"><img src="https://api.codacy.com/project/badge/Grade/61fe95d2311241b6b5051a04493a43c2" alt="codacy"/></a>
<a href="https://www.codefactor.io/repository/github/virtubox/nginx-ee"><img src="https://www.codefactor.io/repository/github/virtubox/nginx-ee/badge" alt="CodeFactor" /></a></p>



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
* HTTP/3 QUIC Support with Mainline Release
* Brotli Support
* TLS v1.3 support
* OpenSSL or LibreSSL
* Cloudflare zlib
* Automated nginx updates cronjob
* Security hardening and performance optimization enabled with proper GCC flags
* An option to omit nginx configuration, allowing usage of third party devops tools

---

## Additional Third-party modules

Nginx current mainline release : **v1.25.5** with HTTP/3 QUIC
Nginx current stable release : **v1.24.0** with Cloudflare HTTP/2 HPACK

* [ngx_cache_purge](https://github.com/FRiCKLE/ngx_cache_purge)
* [headers-more-nginx-module](https://github.com/openresty/headers-more-nginx-module)
* [ngx_brotli](https://github.com/google/ngx_brotli)
* [memc-nginx-module](https://github.com/openresty/memc-nginx-module.git)
* [ngx-devel-kit](https://github.com/simpl/ngx_devel_kit.git)
* [ngx_http_redis](https://github.com/centminmod/ngx_http_redis)
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

* [naxsi WAF](https://github.com/wargio/naxsi)
* [nginx-rtmp-module](https://github.com/arut/nginx-rtmp-module)

---

## Compatibility

### Operating System

#### Recommended

* Ubuntu 22.04 LTS (Jammy)
* Ubuntu 20.04 LTS (Focal)
* Ubuntu 18.04 LTS (Bionic)
* Debian 10 (Buster)
* Debian 11 (Bullseye)

#### Also compatible

* Raspbian 10 (Buster)
* Raspbian 11 (Bullseye)

### Applications

#### LEMP Stack

* EasyEngine v3
* WordOps

#### Plesk

* 17.5.x (Onyx)
* 17.8.x
* 17.9.x
* 18.x (Obsidian)

### HTTP/3 QUIC

Full support of HTTP/3 QUIC is only available with Nginx mainline release and compiled with LibreSSL. More information [here](https://nginx.org/en/docs/http/ngx_http_v3_module.html).

---

## Usage

### One-Step Automated Install

**Default settings** :

* mainline release with HTTP/3
* openssl from system
* without naxsi
* without rtmp

```bash
bash <(wget -qO - vtb.cx/nginx-ee || curl -sL vtb.cx/nginx-ee)
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

Example : Nginx stable release HTTP/2 with naxsi

```bash
bash <(wget -O - vtb.cx/nginx-ee || curl -sL vtb.cx/nginx-ee) --stable --naxsi
```

#### Options available

Nginx build options :

* `--stable` : compile Nginx stable release with HTTP/2
* `--full` : Naxsi + RTMP
* `--dynamic` : Compile Nginx modules as dynamic modules
* `--noconf` : Compile Nginx without any configuring. Useful when you use devops tools like ansible.

Optional third-party modules :

* `--naxsi` : compile nginx with naxsi
* `--rtmp` : compile nginx with rtmp module
* `--libressl` : compile nginx with LibreSSL instead of OpenSSL

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
* [x] Add openssl release choice
* [x] Add more compilation presets
* [x] Add support for LibreSSL
* [x] Add noconf support
* [ ] Add support for config.inc build configuration
* [x] Add HTTP/3 QUIC support

---

## Packages

You are looking for an up-to-date version of Nginx with additional modules but without having to recompile Nginx after new releases ?
Feel free to use the custom Nginx package built for WordOps and available on [Launchpad.net](https://launchpad.net/~wordops/+archive/ubuntu/nginx-wo) (for Ubuntu) and [OpenSuseBuildService](https://build.opensuse.org/package/show/home:virtubox:WordOps/nginx) (for Debian/Ubuntu/Raspbian).

### Add the repository

#### Launchpad

```bash
sudo add-apt-repository ppa:wordops/nginx-wo -uy
```

#### OpenSuseBuildService

Install steps available on [Download page](https://software.opensuse.org/download.html?project=home%3Avirtubox%3AWordOps&package=nginx)

### Install Nginx

```bash
sudo apt install nginx-custom nginx-wo -y
```

## Related

* [WordOps](https://github.com/WordOps/WordOps)
* [Ubuntu-nginx-web-server](https://github.com/VirtuBox/ubuntu-nginx-web-server)
* [Plesk-nginx-fastcgi-cache-template](https://github.com/VirtuBox/plesk-nginx-fascgi-cache-template)
* [Nginx-Cloudflare-real-ip](https://github.com/VirtuBox/nginx-cloudflare-real-ip)
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
