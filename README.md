# Compile the latest nginx mainline release for EasyEngine

This is a script to compile the latest nginx release from source with easyengine. It was currently tested on Ubuntu 16.04 LTS and Debian 8 Jessie.
Feel free to open an issue if you have any error during the compilation.

-----
Nginx current release : **v1.13.8**

others modification :
* ngx_coolkit
* ngx_brotli
* ngx_slowfs_cache
* ngx_http_substitutions_filter_module
* nginx-dynamic-tls-records-patch_1.13.0+
* ngx_http_auth_pam_module
* ngx_pagespeed (optional)
-----

**Compatible Operating System :**
* Ubuntu 16.04 LTS
* Debian 8 Jessie : Just run the command  `apt install libgeoip-dev libpam0g-dev libgd-dev libpcre3-dev libxslt1-dev sudo` before launching the script

-----

### Compile Nginx

Without pagespeed
```
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```

With pagespeed
```
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build-pagespeed.sh)
```
-----

### Nginx configuration

My current Nginx configuration is available here : [nginx.conf](https://github.com/VirtuBox/nginx-ee/blob/master/etc/nginx/nginx.conf)
You can apply it with  : 
```
wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/etc/nginx/nginx.conf
nginx -t
service nginx restart
```

-----

### Additional configurations 

* [Webp support](https://github.com/VirtuBox/nginx-ee/blob/master/doc/webp.md)

-----

Published by <a href="https://virtubox.net" title="VirtuBox">VirtuBox</a>




