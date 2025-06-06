#!/bin/bash
set -e

# version check: https://nginx.org/en/download.html
VERSION=1.18.0
HASH="4c373e7ab5bf91d34a4f11a0c9496561061ba5eee6020db272a17a7228d35f99"

apt install -y autoconf

cd /tmp
curl -O https://nginx.org/download/nginx-$VERSION.tar.gz
sha256sum nginx-$VERSION.tar.gz
echo "$HASH nginx-$VERSION.tar.gz" | sha256sum -c
tar zxf nginx-$VERSION.tar.gz
cd nginx-$VERSION

# nginx-common for boilerplate files etc.
apt install -y nginx-common libpcre3 libpcre3-dev zlib1g zlib1g-dev

cd /tmp
# this is the reason we are compiling by hand...
git clone https://github.com/google/ngx_brotli.git
# now ngx_brotli has brotli as a submodule
cd /tmp/ngx_brotli
git submodule update --init

cd /tmp/nginx-$VERSION
# ignoring depracations with -Wno-deprecated-declarations while we wait for this https://github.com/google/ngx_brotli/issues/39#issuecomment-254093378
./configure --with-cc-opt='-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -Wno-deprecated-declarations' --with-ld-opt='-Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now' --prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-debug --with-pcre-jit --with-ipv6 --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_addition_module --with-http_dav_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_v2_module --with-http_sub_module --with-stream --with-stream_ssl_module --with-mail --with-mail_ssl_module --with-threads --add-module=/tmp/ngx_brotli

make install

mv /usr/share/nginx/sbin/nginx /usr/sbin

cd /
rm -fr /tmp/nginx
rm -fr /tmp/libbrotli
rm -fr /tmp/ngx_brotli
rm -fr /etc/nginx/modules-enabled/*

mkdir -p /etc/nginx/conf.d
