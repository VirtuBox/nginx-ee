# Nginx-EE

## Compile and install the latest nginx releases from source with additional modules with EasyEngine, Plesk Onyx or from scratch

![nginx-ee](https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-ee.png)

---

## Features

* Compile the latest Nginx Mainline or Stable Release
* Install Nginx or replace Nginx package previously installed
* Nginx official modules selection
* Nginx Third-party Additonal selection
* Brotli Support
* TLS v1.3 support (Final)
* Cloudflare HPACK (for Mainline release only)

---

## Additional Third-party modules

Nginx current mainline release : **v1.15.6**
Nginx current stable release : **v1.14.1**

* ngx_cache_purge
* headers-more-nginx-module
* [ngx_brotli](https://github.com/eustas/ngx_brotli)
* srcache-nginx-module
* ngx_http_substitutions_filter_module
* [nginx_dynamic_tls_records](https://github.com/nginx-modules/ngx_http_tls_dyn_size)
* Openssl 1.1.1
* [ipscrub](http://www.ipscrub.org/)
* ngx_http_auth_pam_module
* [virtual-host-traffic-status](https://github.com/vozlt/nginx-module-vts)

optional modules :

* [ngx_pagespeed](https://github.com/apache/incubator-pagespeed-ngx) (latest-beta or latest-stable)
* [naxsi WAF](https://github.com/nbs-system/naxsi)
* [nginx-rtmp-module](https://github.com/arut/nginx-rtmp-module)

---

## Compatibility

### Operating System

* Ubuntu 18.04 LTS (Bionic)
* Ubuntu 16.04 LTS (Xenial)
* Debian 8 (Deprecated)

### Plesk releases

* 17.5.x
* 17.8.x
* 17.9.x

---

## Usage

<!-- TOC -->
   - [Interactive install](#interactive-install)
   - [Non interactive install](#non-interactive-install)
     - [Options available](#options-available)
   - [Nginx modules](#nginx-modules)
     - [Override list of modules built by default with nginx-ee](#override-list-of-modules-built-by-default-with-nginx-ee)
     - [Override list of third-party modules built by default with nginx-ee](#override-list-of-third-party-modules-built-by-default-with-nginx-ee)
   - [Troubleshooting](#troubleshooting)
     - [TLSv1.2 + TLSv1.3](#tlsv12--tlsv13)
     - [TLSv1.0 + TLSv1.1 + TLSv1.2 + TLSv1.3](#tlsv10--tlsv11--tlsv12--tlsv13)
   - [Nginx configurations](#nginx-configurations)
   - [Roadmap](#roadmap)

<!-- /TOC -->

### Interactive install

```bash
bash <(wget -qO - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```

### Non interactive install

```bash
bash <(wget -qO - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh) [options] ...
```

#### Options available

Nginx release (required) :

* `--mainline` : compile nginx mainline release
* `--stable` : compile nginx stable release

Additional modules (optional)

* `--pagespeed`: compile nginx with ngx_pagespeed latest-stable
* `--pagespeed-beta`: compile nginx with ngx_pagespeed latest-beta
* `--naxsi` : compile nginx with naxsi
* `--rtmp` : compile nginx with rtmp module

Example :

Compile Nginx mailine release with pagespeed stable

```bash
bash <(wget -qO - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh) --mainline --pagespeed
```

### Nginx modules

You can choose Nginx official modules and third-party modules you want to compile with Nginx-ee.
The list of official modules built by default and optional modules is available on [Nginx Docs](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#modules-built-by-default)

To override **official modules** compiled with nginx-ee, export the variable **OVERRIDE_NGINX_MODULES** before launching nginx-ee script.

To override **third-party modules** compiled with nginx-ee, export the variable **OVERRIDE_NGINX_ADDITIONAL_MODULES** before laucnhing nginx-ee script.
**Important** : If you want to add a third-party module, you will have to download its source in `/usr/local/src` before launching the compilation.

Examples :

#### Override list of modules built by default with nginx-ee

```bash
# choose modules you want to build
# This is the list of modules built by default with nginx-ee
export OVERRIDE_NGINX_MODULES="--without-http_uwsgi_module \
    --without-mail_imap_module \
    --without-mail_pop3_module \
    --without-mail_smtp_module \
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


# compile nginx-ee with the modules previously selected
bash <(wget -qO - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```

#### Override list of third-party modules built by default with nginx-ee

You can add/remove additional third-party modules compiled with nginx-ee.
Here an example to add the nginx module mod_zip :

```bash
# clone the module repository into /usr/local/src
git clone https://github.com/evanmiller/mod_zip.git /usr/local/src/mod_zip

# add the module to the modules list using the variable OVERRIDE_NGINX_ADDITIONAL_MODULES
# This is the list of third-party modules built by default with nginx-ee + mod_zip module
export OVERRIDE_NGINX_ADDITIONAL_MODULES="--add-module=/usr/local/src/echo-nginx-module \
    --add-module=/usr/local/src/headers-more-nginx-module \
    --add-module=/usr/local/src/ngx_cache_purge \
    --add-module=/usr/local/src/ngx_brotli \
    --add-module=/usr/local/src/ngx_http_substitutions_filter_module \
    --add-module=/usr/local/src/srcache-nginx-module \
    --add-module=/usr/local/src/ngx_http_redis \
    --add-module=/usr/local/src/redis2-nginx-module \
    --add-module=/usr/local/src/memc-nginx-module \
    --add-module=/usr/local/src/ngx_devel_kit \
    --add-module=/usr/local/src/set-misc-nginx-module \
    --add-module=/usr/local/src/ngx_http_auth_pam_module \
    --add-module=/usr/local/src/nginx-module-vts \
    --add-module=/usr/local/src/ipscrubtmp/ipscrub \
    --add-module=/usr/local/src/mod_zip" # add mod_zip module at the end of the list

# compile nginx-ee with the modules previously selected
bash <(wget -qO - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```

## Troubleshooting

TLS v1.3 do not work or browser show error message `ERR_SSL_VERSION_OR_CIPHER_MISMATCH` :

Update nginx ssl_ciphers in `/etc/nginx/nginx.conf` for EasyEngine servers or `/etc/nginx/conf.d/ssl.conf` for Plesk servers

### TLSv1.2 + TLSv1.3

```nginx
    ##
    # SSL Settings
    ##
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'TLS13+AESGCM+AES128:EECDH+AES128';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    ssl_ecdh_curve X25519:sect571r1:secp521r1:secp384r1;
```

### TLSv1.0 + TLSv1.1 + TLSv1.2 + TLSv1.3

```nginx
    ##
    # SSL Settings
    ##
    # intermediate configuration. tweak to your needs.
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers 'TLS13+AESGCM+AES128:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    ssl_ecdh_curve X25519:sect571r1:secp521r1:secp384r1;
```

---

## Nginx configurations

* [Wiki](https://github.com/VirtuBox/nginx-ee/wiki)
* [Ubuntu-nginx-web-server](https://github.com/VirtuBox/ubuntu-nginx-web-server/tree/master/etc/nginx)

---

## Roadmap

* [x] Add choice between stable & mainline release
* [x] Add Nginx configuration examples
* [x] Add Cloudflare HPACK patch
* [x] Add support for servers without EasyEngine
* [x] Add non-interactive installation
* [ ] Add automated update detection
* [x] Add support for Plesk servers
* [x] Add Nginx modules choice

Published & maintained by <a href="https://virtubox.net" title="VirtuBox">VirtuBox</a>
