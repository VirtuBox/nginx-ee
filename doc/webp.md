### Webp support 

Add the file webp.conf in /etc/nginx/conf.d folder :
```
wget -O /etc/nginx/conf.d/webp.conf https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/etc/nginx/conf.d/webp.conf
```
Then add a file wepb-enabled.conf in your website nginx configuration folder /var/www/yoursite.tld/conf/nginx/ with the following content :
```
location ~* ^/wp-content/.+\.(png|jpg)$ {
  add_header Vary Accept;
  add_header "Access-Control-Allow-Origin" "*";
  access_log off;
  log_not_found off;
  expires max;
  try_files $uri$webp_suffix $uri =404;
}
```
Check if there are no error with `nginx -t` and reload nginx with `service nginx reload`

-----
