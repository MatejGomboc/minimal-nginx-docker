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

REM Configure and build Nginx with minimal modules
echo Building Nginx from source (this may take a few minutes)...
docker exec nginx-builder sh -c "cd /tmp/nginx-1.24.0 && ./configure --prefix=/usr/local/nginx --sbin-path=/usr/local/nginx/sbin/nginx --conf-path=/usr/local/nginx/conf/nginx.conf --pid-path=/var/run/nginx.pid --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-pcre --with-http_ssl_module --with-http_v2_module --without-http_scgi_module --without-http_uwsgi_module --without-http_fastcgi_module --without-http_geo_module --without-http_map_module --without-http_split_clients_module --without-http_referer_module --without-http_rewrite_module --without-http_proxy_module --without-http_memcached_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module && make && make install"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to build Nginx
    goto cleanup
)

REM Step 3: Create a minimal filesystem structure
echo Step 3: Creating minimal filesystem structure...
docker exec nginx-builder sh -c "mkdir -p /nginx-minimal/usr/local/nginx && mkdir -p /nginx-minimal/var/log/nginx && mkdir -p /nginx-minimal/var/run && mkdir -p /nginx-minimal/etc && mkdir -p /nginx-minimal/config && cp -r /usr/local/nginx/* /nginx-minimal/usr/local/nginx/ && echo 'nobody:x:65534:65534:nobody:/:/sbin/nologin' > /nginx-minimal/etc/passwd"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to create filesystem structure
    goto cleanup
)

REM Step 4: Find and copy all required shared libraries
echo Step 4: Copying required shared libraries...
docker exec nginx-builder sh -c "ldd /usr/local/nginx/sbin/nginx | grep '=> /' | awk '{print \$3}' | xargs -I '{}' dirname '{}' | sort -u | xargs -I '{}' mkdir -p '/nginx-minimal{}'"
docker exec nginx-builder sh -c "ldd /usr/local/nginx/sbin/nginx | grep '=> /' | awk '{print \$3}' | xargs -I '{}' cp -v '{}' '/nginx-minimal{}'"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to copy shared libraries
    goto cleanup
)

REM Copy dynamic loader if needed
docker exec nginx-builder sh -c "if [ -f /lib/ld-musl-*.so.1 ]; then mkdir -p /nginx-minimal/lib && cp -v /lib/ld-musl-*.so.1 /nginx-minimal/lib/; fi"

REM Step 5: Move the default nginx configuration to a separate directory
echo Step 5: Creating default configuration...
docker exec nginx-builder sh -c "cat > /nginx-minimal/config/default.conf << 'EOF'
worker_processes 1;
events { worker_connections 1024; }
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    server {
        listen       80;
        server_name  localhost;
        location / {
            root   html;
            index  index.html index.htm;
        }
    }
}
EOF"

REM Create a simple index.html file
docker exec nginx-builder sh -c "mkdir -p /nginx-minimal/usr/local/nginx/html && echo '<html><body><h1>Hello from minimal Nginx!</h1></body></html>' > /nginx-minimal/usr/local/nginx/html/index.html"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to create configuration files
    goto cleanup
)

REM Create a startup wrapper script that checks for mounted config
echo Creating startup wrapper script...
docker exec nginx-builder sh -c "cat > /nginx-minimal/usr/local/nginx/sbin/start-nginx.sh << 'EOF'
#!/bin/sh
# Check if user mounted a custom config
if [ -f /config/nginx.conf ]; then
    # Use mounted config
    cp -f /config/nginx.conf /usr/local/nginx/conf/nginx.conf
    echo \"Using custom Nginx configuration from mounted volume\"
else
    # Use default config
    cp -f /config/default.conf /usr/local/nginx/conf/nginx.conf
    echo \"Using default Nginx configuration\"
fi

# Start Nginx in foreground
exec /usr/local/nginx/sbin/nginx -g \"daemon off;\"
EOF"

REM Make the startup script executable
docker exec nginx-builder sh -c "chmod +x /nginx-minimal/usr/local/nginx/sbin/start-nginx.sh"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to create startup script
    goto cleanup
)

REM Step 6: Import the filesystem directly as a Docker image
echo Step 6: Creating Docker image...
docker exec nginx-builder sh -c "tar -C /nginx-minimal -cf - ." | docker import - --change "EXPOSE 80" --change "VOLUME [\"/config\"]" --change "CMD [\"/usr/local/nginx/sbin/start-nginx.sh\"]" minimal-nginx
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
echo To run with custom configuration:
echo docker run -d -p 8080:80 -v %cd%\my-nginx.conf:/config/nginx.conf --name nginx-server minimal-nginx
echo.

endlocal