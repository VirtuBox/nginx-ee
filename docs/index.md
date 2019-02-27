---
title: Nginx-ee - Automated Nginx compilation from sources with additional modules support
layout: default
---

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
<hr />
<p align="center"><a href="https://travis-ci.com/VirtuBox/nginx-ee"><img src="https://travis-ci.com/VirtuBox/nginx-ee.svg?branch=master" alt="build"></a>
<img src="https://img.shields.io/github/license/VirtuBox/nginx-ee.svg" alt="MIT">
<img src="https://img.shields.io/github/stars/VirtuBox/nginx-ee.svg" alt="Stars">
<img src="https://img.shields.io/github/last-commit/virtubox/nginx-ee/master.svg?style=flat" alt="Commits"></p>
<p align="center">
<a href="#features"> Features<a> •
<a href="#additional-third-party-modules"> Modules</a> •
<a href="#compatibility"> Compatibility</a> •
<a href="#usage"> Usage</a> •
<a href="https://github.com/VirtuBox/nginx-ee/wiki/Nginx-modules"> Wiki</a> •
<a href="#credits"> Credits</a>
<p align="center"><img src="https://raw.githubusercontent.com/VirtuBox/nginx-ee/master/nginx-ee.png" alt="Nginx-ee"></p>
<hr />
<h2 id="features">Features</h2>
<ul>
<li>Compile the latest Nginx releases : stable or mainline</li>
<li>Install Nginx or replace Nginx package previously installed</li>
<li>Nginx built-in modules selection</li>
<li>Nginx Third-party module selection</li>
<li>Dynamic modules support</li>
<li>Brotli Support</li>
<li>TLS v1.3 support (Final)</li>
<li>Cloudflare HPACK (for Mainline release only)</li>
<li>Cloudflare zlib</li>
<li>Setup a daily cronjob to automated nginx updates</li>
<li>Compilation with GCC-7/8</li>
<li>Security hardening and performance optimization enabled with proper GCC flags</li>
</ul>
<hr />
<h2 id="additional-third-party-modules">Additional Third-party modules</h2>
<p>Nginx current mainline release : <strong>v1.15.9</strong>
Nginx current stable release : <strong>v1.14.2</strong></p>
<ul>
<li><a href="https://github.com/FRiCKLE/ngx_cache_purge">ngx_cache_purge</a></li>
<li><a href="https://github.com/openresty/headers-more-nginx-module">headers-more-nginx-module</a></li>
<li><a href="https://github.com/eustas/ngx_brotli">ngx_brotli</a></li>
<li><a href="https://github.com/openresty/memc-nginx-module.git">memc-nginx-module</a></li>
<li><a href="https://github.com/simpl/ngx_devel_kit.git">ngx-devel-kit</a></li>
<li><a href="https://github.com/openresty/srcache-nginx-module">srcache-nginx-module</a></li>
<li><a href="https://github.com/yaoweibin/ngx_http_substitutions_filter_module">ngx_http_substitutions_filter_module</a></li>
<li><a href="https://github.com/nginx-modules/ngx_http_tls_dyn_size">nginx_dynamic_tls_records</a></li>
<li><a href="https://github.com/openssl/openssl">OpenSSL</a></li>
<li><a href="http://www.ipscrub.org/">ipscrub</a></li>
<li><a href="https://github.com/sto/ngx_http_auth_pam_module">ngx_http_auth_pam_module</a></li>
<li><a href="https://github.com/vozlt/nginx-module-vts">virtual-host-traffic-status</a></li>
<li><a href="https://github.com/cloudflare/zlib.git">Cloudflare zlib</a></li>
<li><a href="https://github.com/openresty/redis2-nginx-module.git">redis2-nginx-module</a></li>
</ul>
<p>Optional modules :</p>
<ul>
<li><a href="https://github.com/apache/incubator-pagespeed-ngx">ngx_pagespeed</a> (latest-beta or latest-stable)</li>
<li><a href="https://github.com/nbs-system/naxsi">naxsi WAF</a></li>
<li><a href="https://github.com/arut/nginx-rtmp-module">nginx-rtmp-module</a></li>
</ul>
<hr />
<h2 id="compatibility">Compatibility</h2>
<h3 id="operating-system">Operating System</h3>
<h4 id="recommended">Recommended</h4>
<ul>
<li>Ubuntu 18.04 LTS (Bionic)</li>
<li>Ubuntu 16.04 LTS (Xenial)</li>
</ul>
<h4 id="also-compatible">Also compatible</h4>
<ul>
<li>Debian 9 (Stretch)</li>
<li>Debian 8 (Jessie)</li>
<li>Raspbian (Stretch)</li>
</ul>
<h3 id="plesk-releases">Plesk releases</h3>
<ul>
<li>17.5.x</li>
<li>17.8.x</li>
<li>17.9.x</li>
</ul>
<hr />
<h2 id="usage">Usage</h2>
<ul>
<li><a href="#default-non-interactive-install">Default non-interactive install</a></li>
<li><a href="#interactive-install">Interactive install</a></li>
<li><a href="#custom-installation">Custom installation</a>
<ul>
<li><a href="#options-available">Options available</a></li>
</ul>
</li>
</ul>
<h3 id="default-non-interactive-install">Default non-interactive install</h3>
<p>By default, nginx-ee compile Nginx Mainline release without Pagespeed, Naxsi or RTMP</p>
<pre><code class="language-bash">bash &lt;(wget -O - virtubox.net/nginx-ee || curl -sL virtubox.net/nginx-ee)
</code></pre>
<h3 id="interactive-install">Interactive install</h3>
<p>Interactive installation is available with arguments <code>-i</code> or <code>--interactive</code></p>
<pre><code class="language-bash">bash &lt;(wget -O - virtubox.net/nginx-ee || curl -sL virtubox.net/nginx-ee) --interactive
</code></pre>
<h3 id="custom-installation">Custom installation</h3>
<p>Exemple : Nginx stable release with pagespeed and naxsi</p>
<pre><code class="language-bash">bash &lt;(wget -O - virtubox.net/nginx-ee || curl -sL virtubox.net/nginx-ee) --stable --pagespeed --naxsi
</code></pre>
<h4 id="options-available">Options available</h4>
<p>Nginx build options :</p>
<ul>
<li><code>--stable</code> : compile Nginx stable release</li>
<li><code>--full</code> : Naxsi + PageSpeed + RTMP</li>
<li><code>--dynamic</code> : Compile Nginx modules as dynamic modules</li>
</ul>
<p>Optional third-party modules :</p>
<ul>
<li><code>--pagespeed</code>: compile nginx with ngx_pagespeed latest-stable</li>
<li><code>--pagespeed-beta</code>: compile nginx with ngx_pagespeed latest-beta</li>
<li><code>--naxsi</code> : compile nginx with naxsi</li>
<li><code>--rtmp</code> : compile nginx with rtmp module</li>
</ul>
<p>Extras :</p>
<ul>
<li><code>--cron</code> : setup daily cronjob to update nginx each time a new release is available</li>
</ul>
<h3 id="nginx-modules">Nginx modules</h3>
<p>You can choose Nginx built-in and third-party modules you want to compile with Nginx-ee. You can find more informations in the <a href="https://github.com/VirtuBox/nginx-ee/wiki/Nginx-modules">Wiki</a></p>
<hr />
<h2 id="related-repositories--pages">Related repositories &amp; pages</h2>
<ul>
<li><a href="https://github.com/VirtuBox/nginx-ee/wiki">Nginx-ee Wiki</a></li>
<li><a href="https://github.com/VirtuBox/ubuntu-nginx-web-server">Ubuntu-nginx-web-server</a> : repository with all custom nginx configurations used by VirtuBox</li>
<li><a href="https://github.com/VirtuBox/wo-nginx-setup">Wo-nginx-setup</a> : automated wordops setup script</li>
<li><a href="https://github.com/VirtuBox/plesk-nginx-fascgi-cache-template">Plesk-nginx-fastcgi-cache-template</a> : Plesk Onyx custom hosting templates with fastcgi_cache support</li>
<li><a href="https://github.com/VirtuBox/nginx-cloudflare-real-ip">Nginx-cloudflare-real-ip</a> : Bash script to restore visitor real IP under Cloudflare with Nginx</li>
</ul>
<hr />
<h2 id="roadmap">Roadmap</h2>
<ul class="contains-task-list">
<li class="task-list-item"><input disabled="disabled" type="checkbox" checked="checked" /> Add choice between stable &amp; mainline release</li>
<li class="task-list-item"><input disabled="disabled" type="checkbox" checked="checked" /> Add Nginx configuration examples</li>
<li class="task-list-item"><input disabled="disabled" type="checkbox" checked="checked" /> Add Cloudflare HPACK patch</li>
<li class="task-list-item"><input disabled="disabled" type="checkbox" checked="checked" /> Add support for servers without EasyEngine</li>
<li class="task-list-item"><input disabled="disabled" type="checkbox" checked="checked" /> Add non-interactive installation</li>
<li class="task-list-item"><input disabled="disabled" type="checkbox" checked="checked" /> Add automated update detection</li>
<li class="task-list-item"><input disabled="disabled" type="checkbox" checked="checked" /> Add support for Plesk servers</li>
<li class="task-list-item"><input disabled="disabled" type="checkbox" checked="checked" /> Add Nginx modules choice</li>
<li class="task-list-item"><input disabled="disabled" type="checkbox" checked="checked" /> Add support for Debian 9</li>
<li class="task-list-item"><input disabled="disabled" type="checkbox" /> Add support for config.inc build configuration</li>
<li class="task-list-item"><input disabled="disabled" type="checkbox" /> Add openssl release choice</li>
<li class="task-list-item"><input disabled="disabled" type="checkbox" /> Add more compilation presets</li>
</ul>
<h2 id="credits">Credits</h2>
<ul>
<li><a href="https://github.com/centminmod/centminmod">centminmod</a> : Nginx, Nginx modules &amp; various other patches</li>
<li><a href="https://github.com/hakasenyang/openssl-patch">hakase</a> : OpenSSL-patch</li>
</ul>
<p>Published &amp; maintained by <a href="https://virtubox.net" title="VirtuBox">VirtuBox</a></p>
