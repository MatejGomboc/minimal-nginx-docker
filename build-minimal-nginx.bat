@echo off
setlocal enabledelayedexpansion

echo Building minimal Nginx Docker image...
echo.

REM Step 1: Create a build container
echo Step 1: Creating build container...
docker run -d --name nginx-builder alpine:latest tail -f /dev/null
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to create build container
    exit /b 1
)

REM Step 2: Install build dependencies and compile Nginx from source
echo Step 2: Installing build dependencies...
docker exec nginx-builder apk add --no-cache gcc libc-dev make openssl-dev pcre-dev zlib-dev linux-headers wget
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to install build dependencies
    goto cleanup
)

REM Download and extract Nginx source
echo Downloading and extracting Nginx...
docker exec nginx-builder sh -c "cd /tmp && wget https://nginx.org/download/nginx-1.24.0.tar.gz && tar -zxf nginx-1.24.0.tar.gz"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to download or extract Nginx
    goto cleanup
)

REM Configure and build Nginx with minimal modules using standard paths
echo Building Nginx from source (this may take a few minutes)...
docker exec nginx-builder sh -c "cd /tmp/nginx-1.24.0 && ./configure --prefix=/var/www --sbin-path=/usr/local/sbin/nginx --conf-path=/etc/nginx/nginx.conf --pid-path=/var/run/nginx.pid --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-pcre --with-http_ssl_module --with-http_v2_module --without-http_scgi_module --without-http_uwsgi_module --without-http_fastcgi_module --without-http_geo_module --without-http_map_module --without-http_split_clients_module --without-http_referer_module --without-http_rewrite_module --without-http_proxy_module --without-http_memcached_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module && make && make install"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to build Nginx
    goto cleanup
)

REM Step 3: Create a minimal filesystem structure with standard paths
echo Step 3: Creating minimal filesystem structure...
docker exec nginx-builder sh -c "mkdir -p /nginx-minimal/etc/nginx && mkdir -p /nginx-minimal/var/log/nginx && mkdir -p /nginx-minimal/var/run && mkdir -p /nginx-minimal/var/www && mkdir -p /nginx-minimal/usr/local/sbin && cp -r /etc/nginx/* /nginx-minimal/etc/nginx/ && cp /usr/local/sbin/nginx /nginx-minimal/usr/local/sbin/ && echo 'nobody:x:65534:65534:nobody:/:/sbin/nologin' > /nginx-minimal/etc/passwd"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to create filesystem structure
    goto cleanup
)

REM Step 4: Copy necessary libraries - using simpler approach for Windows
echo Step 4: Copying required shared libraries...

REM Create lib directory and copy dynamic loader
docker exec nginx-builder sh -c "mkdir -p /nginx-minimal/lib"
docker exec nginx-builder sh -c "cp -v /lib/ld-musl-*.so.1 /nginx-minimal/lib/ 2>/dev/null || true"

REM Copy required libraries - direct command approach
docker exec nginx-builder sh -c "for lib in $(ldd /usr/local/sbin/nginx | grep '=>' | awk '{print $3}'); do if [ -f \"$lib\" ]; then mkdir -p /nginx-minimal$(dirname $lib); cp -v $lib /nginx-minimal$(dirname $lib)/; fi; done"

REM Step 5: Create a basic nginx configuration
echo Step 5: Creating default configuration...

REM Use echo inside the container to create the config file
docker exec nginx-builder sh -c "echo 'worker_processes 1;' > /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo 'events { worker_connections 1024; }' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo 'http {' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '    include       mime.types;' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '    default_type  application/octet-stream;' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '    sendfile        on;' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '    keepalive_timeout  65;' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '    # Log configuration' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '    access_log  /var/log/nginx/access.log;' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '    error_log   /var/log/nginx/error.log;' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '    server {' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '        listen       80;' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '        server_name  localhost;' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '        location / {' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '            root   /var/www;' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '            index  index.html index.htm;' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '        }' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '    }' >> /nginx-minimal/etc/nginx/nginx.conf"
docker exec nginx-builder sh -c "echo '}' >> /nginx-minimal/etc/nginx/nginx.conf"

REM Create a simple index.html file
docker exec nginx-builder sh -c "mkdir -p /nginx-minimal/var/www && echo '<html><body><h1>Hello from minimal Nginx!</h1></body></html>' > /nginx-minimal/var/www/index.html"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to create configuration files
    goto cleanup
)

REM Ensure log directory exists and has proper permissions
docker exec nginx-builder sh -c "chmod 755 /nginx-minimal/var/log/nginx && touch /nginx-minimal/var/log/nginx/access.log /nginx-minimal/var/log/nginx/error.log && chmod 644 /nginx-minimal/var/log/nginx/access.log /nginx-minimal/var/log/nginx/error.log"

REM Step 6: Import the filesystem directly as a Docker image
echo Step 6: Creating Docker image...
docker exec nginx-builder sh -c "tar -C /nginx-minimal -cf - ." | docker import - --change "EXPOSE 80" --change "VOLUME [\"/etc/nginx\", \"/var/log/nginx\", \"/var/www\"]" --change "CMD [\"/usr/local/sbin/nginx\", \"-g\", \"daemon off;\", \"-c\", \"/etc/nginx/nginx.conf\"]" minimal-nginx
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to create Docker image
    goto cleanup
)

REM Step 7: Clean up
:cleanup
echo Step 7: Cleaning up...
docker stop nginx-builder
docker rm nginx-builder

REM Show the image size
echo.
docker images minimal-nginx

echo.
echo Minimal Nginx Docker image created successfully!
echo.
echo To run with default configuration:
echo docker run -d -p 8080:80 --name nginx-server minimal-nginx
echo.
echo To run with custom configuration and persistent logs:
echo docker run -d -p 8080:80 -v %cd%\nginx.conf:/etc/nginx/nginx.conf -v %cd%\logs:/var/log/nginx -v %cd%\www:/var/www --name nginx-server minimal-nginx
echo.

endlocal