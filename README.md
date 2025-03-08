# Minimal Nginx Docker Image

This project demonstrates how to create the smallest possible Docker image for Nginx by compiling it from source and extracting only the necessary files and dependencies.

## Why build a minimal Nginx image?

- **Extremely small size**: Resulting image is typically 7-15MB compared to 20-30MB for nginx:alpine and 130MB+ for nginx:latest
- **Reduced attack surface**: Fewer components means fewer potential vulnerabilities
- **Faster downloads and deployments**: Smaller images pull and start faster
- **Learning opportunity**: Understand exactly what components are necessary for Nginx to run

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

## How it works

The build process follows these steps:

1. Creates a temporary Alpine container for building
2. Installs build dependencies and compiles Nginx from source with minimal modules
3. Creates a minimal filesystem with only required files
4. Identifies and copies all necessary shared libraries
5. Creates a basic Nginx configuration as a default
6. Creates a startup script that can use external configuration
7. Imports the minimal filesystem directly as a Docker image
8. Adds metadata like EXPOSE, VOLUME, and CMD

## Running the minimal Nginx image

### With default configuration

```bash
docker run -d -p 8080:80 --name nginx-server minimal-nginx
```

### With custom configuration file

Create your own `nginx.conf` file and mount it:

```bash
# Linux/macOS
docker run -d -p 8080:80 -v $(pwd)/my-nginx.conf:/config/nginx.conf --name nginx-server minimal-nginx

# Windows (Command Prompt)
docker run -d -p 8080:80 -v %cd%\my-nginx.conf:/config/nginx.conf --name nginx-server minimal-nginx

# Windows (PowerShell)
docker run -d -p 8080:80 -v ${PWD}\my-nginx.conf:/config/nginx.conf --name nginx-server minimal-nginx
```

Then visit http://localhost:8080 in your browser to see Nginx in action.

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