# Bash script to compile the latest nginx release from source with EasyEngine

This is a script to compile the latest nginx release from source with easyengine. It was currently tested on Ubuntu 16.04 LTS.
Feel free to open an issue if you have any error during the compilation.

-----
Nginx current version : 1.13.7

others modification :
* ngx_coolkit
* ngx_brotli
* ngx_slowfs_cache
* ngx_http_substitutions_filter_module
* nginx-dynamic-tls-records-patch_1.13.0+
* ngx_http_auth_pam_module
* ngx_pagespeed (optional)

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

### Webp support 

Add the file webp.conf in /etc/nginx/conf.d folder :
```
wget -O /etc/nginx/conf.d/webp.conf https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/etc/nginx/conf.d/webp.conf
```
Then add a file wepb-enabled.conf in your website nginx configuration folder /var/www/yoursite.tld/conf/nginx/ with the following content :
```
location ~* ^/wp-content/.+\.(png|jpg)$ {
  add_header Vary Accept;
  try_files $uri$webp_suffix $uri =404;
}
```
Check if there are no error with `nginx -t` and reload nginx with `service nginx reload`

-----

### Error during the compilation

1. Run the pre-compilation part with this script : 
```
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/debug/pre-compile.sh)
```
2. If there is no error during the first part, launch the compilation configuration :
```
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/debug/configure.sh)
```
Then open an issue or answer on the  [rtcamp community thread](http://community.rtcamp.com/t/compile-the-latest-nginx-release-from-source-with-easyengine/9912) with error logs and informations about your server.




