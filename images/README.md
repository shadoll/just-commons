# Container Images Module

The images module provides comprehensive container image management capabilities including building, pushing, pulling, tagging, and cleaning images with support for multi-architecture builds and flexible naming conventions.

## Quick Start

```bash
# Build image with default settings
just images build

# Push with auto-generated commit tag
just images push

# Push latest (tags and pushes all architectures as latest)
just images push latest

# Show image information
just images info

# List all project images
just images list

# Clean project images
just images clean
```

## Image Naming Logic

The module uses a flexible naming system with clear priority order:

### 1. Full Image Name Override (Highest Priority)
```bash
# .env
IMAGE_NAME=ghcr.io/shkafnik/nikamebel-info
```

When `IMAGE_NAME` is set, it's used exactly as specified for all operations.

### 2. Component-Based Naming (Default)
```bash
# .env
REGISTRY=ghcr.io
REGISTRY_NAMESPACE=shkafnik
PROJECT_NAME=nikamebel-info
```

Image name is built as: `{REGISTRY}/{REGISTRY_NAMESPACE}/{PROJECT_NAME}:{TAG}`

### 3. Project Name Detection Priority
1. **`PROJECT_NAME`** from `.env` (highest priority)
2. **Auto-detection logic**:
   - If single Containerfile in root → use root folder name
   - If multiple Containerfiles in subfolders → use subfolder name
   - If `docker/` subfolder detected → use root folder name
3. **Current folder basename** (fallback)

## Multi-Architecture Support

### Default Behavior
- **Always builds**: `linux/amd64` and `linux/arm64`
- **Automatic detection**: Checks Containerfile for platform specifications
- **Platform override**: If `--platform` found in Containerfile, builds only that platform

### Environment Configuration
```bash
# .env - Override default platforms
DEFAULT_PLATFORMS=linux/arm64,linux/amd64

# Single platform builds
DEFAULT_PLATFORMS=linux/amd64
```

### Platform Detection Examples
```dockerfile
# This will build only for linux/amd64
FROM --platform=linux/amd64 alpine:latest

# This will build for default platforms (arm64 + amd64)
FROM alpine:latest
```

## Tag Management

### Default Tagging
- **Regular builds**: `commit-{short-git-hash}` (e.g., `commit-a1b2c3d`)
- **Non-git repos**: `build-{timestamp}` (e.g., `build-20240315-143022`)

### Manual Tags
```bash
# Build with custom tag
just images build "" "v1.2.3"

# Push specific tag
just images push "" "v1.2.3"
```

### Latest Tag Handling
```bash
# Special latest command - finds all existing tags and:
# 1. Tags them as 'latest'
# 2. Pushes all 'latest' images (all architectures)
just images push latest
```

## Environment Variables

### Registry Configuration
```bash
# Registry settings
REGISTRY=ghcr.io                    # Default: ghcr.io
REGISTRY_NAMESPACE=shkafnik         # Required for registry operations
GITHUB_USERNAME=shkafnik            # Fallback for REGISTRY_NAMESPACE
GITHUB_TOKEN=ghp_xxxx               # Required for private registries

# Full override (highest priority)
IMAGE_NAME=ghcr.io/custom/path      # Overrides all other naming logic
```

### Project Configuration
```bash
# Project identification
PROJECT_NAME=nikamebel-info         # Override auto-detection

# Build configuration
DEFAULT_PLATFORMS=linux/arm64,linux/amd64  # Default platforms to build
```

### Runtime Configuration
```bash
# Container runtime
DOCKER=podman                       # Default: docker
DOCKER_COMPOSE=podman-compose      # Default: docker compose
```

## Commands Reference

### Build Commands
```bash
# Auto-discover and build with commit tag
just images build

# Build specific project
just images build myproject

# Build with custom tag
just images build "" "v1.2.3"

# Build specific project with tag
just images build myproject "v1.2.3"
```

### Push Commands
```bash
# Push with auto-generated tag
just images push

# Push specific tag
just images push "" "v1.2.3"

# Push latest (special handling)
just images push latest

# Push specific project
just images push myproject
```

### Pull Commands
```bash
# Pull latest tag
just images pull

# Pull specific tag
just images pull "" "v1.2.3"

# Pull specific project
just images pull myproject "v1.2.3"
```

### Management Commands
```bash
# Tag existing image
just images tag myproject "new-tag"

# Show image information
just images info

# List all project images
just images list

# Clean project images (with confirmation)
just images clean

# Build all projects with Containerfiles
just images build-all
```

## Architecture Detection

The module automatically detects the build context and Containerfile location:

1. **Current directory**: `./Containerfile` or `./Dockerfile`
2. **Docker subdirectory**: `./docker/Containerfile` or `./docker/Dockerfile`
3. **Project subdirectories**: `{project}/Containerfile` or `{project}/Dockerfile`

## Multi-Platform Build Process

### For Multi-Platform Images
```bash
# Creates manifest with multiple architectures
docker buildx build --platform linux/amd64,linux/arm64 \
  -t ghcr.io/shkafnik/nikamebel-info:commit-abc123 \
  --push .
```

### For Single Platform Images
```bash
# Regular build for detected platform
docker build -t ghcr.io/shkafnik/nikamebel-info:commit-abc123 .
```

## Latest Tag Workflow

When you run `just images push latest`:

1. **Discovery**: Auto-discover project name
2. **Search**: Find all existing images for the project
3. **Tag**: Tag all found images with `latest`
4. **Push**: Push all `latest` tagged images (all architectures)

This ensures that `latest` always points to your most recent build across all supported architectures.

## Error Handling

### Common Issues and Solutions

**Missing registry credentials:**
```bash
# Set in .env
REGISTRY_NAMESPACE=your-namespace
GITHUB_TOKEN=your-token
```

**Platform build failures:**
```bash
# Check buildx setup
docker buildx create --use
docker buildx inspect --bootstrap
```

**Image not found:**
```bash
# List available images
just images list

# Check project name detection
just images info
```

## Examples

### Basic Workflow
```bash
# Build and push commit-tagged image
just images build
just images push

# Later, mark as latest and push
just images push latest
```

### Custom Project Setup
```bash
# .env configuration
PROJECT_NAME=my-custom-name
REGISTRY_NAMESPACE=myorg
DEFAULT_PLATFORMS=linux/amd64

# Build and push
just images build
just images push
```

### Multi-Project Repository
```bash
# Build specific project
just images build frontend
just images build backend

# Build all projects
just images build-all
```

## Integration with just-commons

This module integrates seamlessly with other just-commons modules:

- **Registry module**: For authentication (`just registry login`)
- **Container module**: For runtime management
- **Core utilities**: For project discovery and runtime detection

For complete project setup, see the main project documentation.