# nginx-ee

This is a script to compile the latest nginx release from source with easyengine. It was currently tested on Ubuntu 16.04 LTS.
Feel free to open an issue if you have any error during the compilation.

-----
Nginx current version : 1.13.7

others modification :
* ngx_coolkit
* ngx_brotli
* ngx_slowfs_cache
* ngx_http_substitutions_filter_module
* nginx-dynamic-tls-records-patch_1.11.5
* ngx_pagespeed (optional)

-----

## Compile Nginx

Without pagespeed
```
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build.sh)
```

With pagespeed
```
bash <(wget -O - https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-build-pagespeed.sh)
```

## Nginx configuration

My current Nginx configuration is available here : [nginx.conf](https://github.com/VirtuBox/nginx-ee/blob/master/nginx.conf)
You can apply it with  : 
```
wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx.conf
nginx -t
service nginx restart
```



