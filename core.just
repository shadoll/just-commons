# Core utilities shared across all just-commons modules

# Auto-discover project name from current directory
_discover_project:
    #!/usr/bin/env bash
    echo "$(basename $(pwd))"

# Auto-discover containerfile and return path and project info
# Usage: _discover_containerfile [directory]
# Returns: containerfile_path project_name build_context
_discover_containerfile_in dir="":
    #!/usr/bin/env bash
    set -euo pipefail

    dir="{{dir}}"
    if [ -z "$dir" ]; then
        dir="."
    fi

    # Check for Containerfile or Dockerfile in the specified directory
    if [ -f "$dir/Containerfile" ]; then
        echo "$dir/Containerfile $(basename $(realpath $dir)) $dir/"
    elif [ -f "$dir/Dockerfile" ]; then
        echo "$dir/Dockerfile $(basename $(realpath $dir)) $dir/"
    # Check ./docker folder (only when dir is current directory)
    elif [ "$dir" = "." ] && [ -f "docker/Containerfile" ]; then
        echo "docker/Containerfile $(basename $(pwd)) ."
    elif [ "$dir" = "." ] && [ -f "docker/Dockerfile" ]; then
        echo "docker/Dockerfile $(basename $(pwd)) ."
    else
        echo "Error: No Containerfile or Dockerfile found in $dir" >&2
        if [ "$dir" = "." ]; then
            echo "  - ./Containerfile" >&2
            echo "  - ./Dockerfile" >&2
            echo "  - ./docker/Containerfile" >&2
            echo "  - ./docker/Dockerfile" >&2
        else
            echo "  - $dir/Containerfile" >&2
            echo "  - $dir/Dockerfile" >&2
        fi
        exit 1
    fi

# Auto-discover containerfile from current directory (backward compatibility)
_discover_containerfile:
    #!/usr/bin/env bash
    just _discover_containerfile_in

# Detect container runtime (Docker or Podman)
_detect_runtime:
    #!/usr/bin/env bash
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        echo "docker"
    elif command -v podman >/dev/null 2>&1; then
        echo "podman"
    else
        echo "Error: No container runtime available (docker or podman)" >&2
        exit 1
    fi

# Detect compose command based on available and working container runtime
_detect_compose:
    #!/usr/bin/env bash
    # Check Docker first - but make sure daemon is actually running
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        # Docker daemon is running, check for compose
        if docker compose version >/dev/null 2>&1; then
            echo "docker compose"
        elif command -v docker-compose >/dev/null 2>&1; then
            echo "docker-compose"
        else
            echo "Error: Docker is running but no compose tool found" >&2
            exit 1
        fi
    # Check Podman if Docker is not available or not running
    elif command -v podman >/dev/null 2>&1; then
        if command -v podman-compose >/dev/null 2>&1; then
            echo "podman-compose"
        else
            echo "Error: Podman found but podman-compose not available" >&2
            exit 1
        fi
    else
        echo "Error: No container runtime (Docker or Podman) found" >&2
        exit 1
    fi

# Environment detection and validation
[group('environment')]
env-check:
    #!/usr/bin/env bash
    set -euo pipefail


    echo "================================================"
    echo "  Container Environment Detection"
    echo "================================================"
    echo ""

    # Check Docker
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            echo -e "{{GREEN}}✓ Docker Engine detected and running{{NORMAL}}"
            docker_available=true
        else
            echo -e "{{YELLOW}}⚠ Docker is installed but daemon is not running{{NORMAL}}"
            docker_available=false
        fi
    else
        echo -e "{{RED}}✗ Docker not found{{NORMAL}}"
        docker_available=false
    fi

    # Check Podman
    if command -v podman >/dev/null 2>&1; then
        echo -e "{{GREEN}}✓ Podman detected{{NORMAL}}"
        podman_available=true
    else
        echo -e "{{RED}}✗ Podman not found{{NORMAL}}"
        podman_available=false
    fi

    echo ""
    echo "================================================"
    echo "  SUMMARY"
    echo "================================================"

    if [ "$docker_available" = true ] || [ "$podman_available" = true ]; then
        echo -e "{{GREEN}}🎉 Container runtime available!{{NORMAL}}"
        echo ""
        echo "You can use these universal commands:"
        echo "  just images build <project>   # Build any project image"
        echo "  just container start <service> # Start any service"
        echo "  just registry login           # Login to registry"
    else
        echo -e "{{RED}}❌ No container runtime available{{NORMAL}}"
        echo ""
        echo "Please install Docker or Podman:"
        echo "  • Docker: https://docs.docker.com/get-docker/"
        echo "  • Podman: https://podman.io/getting-started/installation"
    fi