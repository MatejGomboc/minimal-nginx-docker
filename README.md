# Minimal Nginx Docker Image for Reverse Proxy

This project creates an ultra-minimal Docker image for Nginx specifically designed for reverse proxy scenarios where you need to:

1. Serve static frontend assets (HTML, CSS, JS)
2. Proxy API requests to backend services

At 7-15MB in size, this image is perfect for microservice architectures where Nginx serves as a lightweight gateway/edge service.

## Why use this minimal Nginx image?

- **Extremely small footprint**: 7-15MB compared to 20-30MB for nginx:alpine and 130MB+ for nginx:latest
- **Minimal attack surface**: Contains only what's needed for proxy/static file serving
- **Fast startup**: Smaller images pull and deploy faster, ideal for scaling and CI/CD pipelines
- **Resource efficient**: Low memory usage, perfect for containerized environments
- **External configuration**: Mount your Nginx config without rebuilding the image

## Requirements

- Docker installed on your system
- Bash shell (Linux/macOS) or Command Prompt/PowerShell (Windows)

## How to build

### Linux/macOS

```bash
# Clone this repository
git clone https://github.com/MatejGomboc-Claude-MCP/minimal-nginx-docker.git
cd minimal-nginx-docker

# Make the build script executable
chmod +x build-minimal-nginx.sh

# Run the build script
./build-minimal-nginx.sh
```

### Windows

```cmd
# Clone this repository
git clone https://github.com/MatejGomboc-Claude-MCP/minimal-nginx-docker.git
cd minimal-nginx-docker

# Run the build script
build-minimal-nginx.bat
```

## Running as a reverse proxy

### Basic setup with default configuration

```bash
docker run -d -p 80:80 --name nginx-proxy minimal-nginx
```

### Using with a backend API service

Using Docker Compose is the recommended approach for connecting to your backend:

```yaml
# docker-compose.yml example
version: '3'

services:
  nginx:
    image: minimal-nginx
    ports:
      - "80:80"
    volumes:
      - ./sample-nginx.conf:/config/nginx.conf
      - ./frontend:/usr/local/nginx/html
    depends_on:
      - backend-api

  backend-api:
    image: your-backend-api-image
    expose:
      - "8080"
```

### Custom reverse proxy configuration

The repository includes a sample reverse proxy configuration. To use it:

```bash
# Linux/macOS
docker run -d -p 80:80 -v $(pwd)/sample-nginx.conf:/config/nginx.conf --name nginx-proxy minimal-nginx

# Windows (Command Prompt)
docker run -d -p 80:80 -v %cd%\sample-nginx.conf:/config/nginx.conf --name nginx-proxy minimal-nginx

# Windows (PowerShell)
docker run -d -p 80:80 -v ${PWD}\sample-nginx.conf:/config/nginx.conf --name nginx-proxy minimal-nginx
```

### Mounting static frontend files

You can also mount your frontend assets:

```bash
# Linux/macOS
docker run -d -p 80:80 \
  -v $(pwd)/sample-nginx.conf:/config/nginx.conf \
  -v $(pwd)/frontend:/usr/local/nginx/html \
  --name nginx-proxy minimal-nginx

# Windows (simplified)
docker run -d -p 80:80 -v %cd%\sample-nginx.conf:/config/nginx.conf -v %cd%\frontend:/usr/local/nginx/html --name nginx-proxy minimal-nginx
```

## Sample Nginx configuration explained

The included `sample-nginx.conf` is optimized for the reverse proxy use case:

- Serves static frontend assets with proper caching headers
- Proxies API requests to a backend service
- Includes response caching for GET requests
- Sets security headers
- Handles SPA routing by redirecting to index.html
- Optimized for performance with compression, caching, and buffer settings

## Customizing the build

You can modify the build scripts to:

- Change the Nginx version
- Add or remove modules
- Customize the default configuration
- Add additional files to the image

## Alternative Dockerfile approach

The repository also includes `Dockerfile.alternative` which provides a multi-stage build approach. To use it:

```bash
docker build -t minimal-nginx-dockerfile -f Dockerfile.alternative .
```

While slightly larger than the script-based approach, it offers a more familiar Docker workflow.

## License

MIT