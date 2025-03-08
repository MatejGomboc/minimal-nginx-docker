# Minimal Nginx Docker Image

This project demonstrates how to create the smallest possible Docker image for Nginx by compiling it from source and extracting only the necessary files and dependencies.

## Why build a minimal Nginx image?

- **Extremely small size**: Resulting image is typically 7-15MB compared to 20-30MB for nginx:alpine and 130MB+ for nginx:latest
- **Reduced attack surface**: Fewer components means fewer potential vulnerabilities
- **Faster downloads and deployments**: Smaller images pull and start faster
- **Learning opportunity**: Understand exactly what components are necessary for Nginx to run

## Requirements

- Docker installed on your system
- Bash shell

## How to build

```bash
# Clone this repository
git clone https://github.com/MatejGomboc-Claude-MCP/minimal-nginx-docker.git
cd minimal-nginx-docker

# Make the build script executable
chmod +x build-minimal-nginx.sh

# Run the build script
./build-minimal-nginx.sh
```

## How it works

The build process follows these steps:

1. Creates a temporary Alpine container for building
2. Installs build dependencies and compiles Nginx from source with minimal modules
3. Creates a minimal filesystem with only required files
4. Identifies and copies all necessary shared libraries
5. Creates a basic Nginx configuration
6. Imports the minimal filesystem directly as a Docker image
7. Adds metadata like EXPOSE and CMD

## Running the minimal Nginx image

```bash
docker run -d -p 8080:80 --name minimal-nginx minimal-nginx
```

Then visit http://localhost:8080 in your browser to see Nginx in action.

## Customizing the build

You can modify the `build-minimal-nginx.sh` script to:

- Change the Nginx version
- Add or remove modules
- Customize the default configuration
- Add additional files to the image

## License

MIT