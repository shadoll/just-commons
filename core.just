# Core utilities shared across all just-commons modules

# Auto-discover project name from current directory
_discover_project:
    #!/usr/bin/env bash
    echo "$(basename $(pwd))"

# Enhanced project name detection with priority order
# Priority: PROJECT_NAME env var > auto-detection > folder name
_get_project_name:
    #!/usr/bin/env bash
    set -euo pipefail

    # 1. Check PROJECT_NAME environment variable (highest priority)
    if [ -n "${PROJECT_NAME:-}" ]; then
        echo "$PROJECT_NAME"
        exit 0
    fi

    # 2. Auto-detection logic
    project_name=""

    # Check if we're in root with single Containerfile
    if [ -f "Containerfile" ] || [ -f "Dockerfile" ] || [ -f "docker/Containerfile" ] || [ -f "docker/Dockerfile" ]; then
        # Check for multiple projects (subdirectories with Containerfiles)
        subproject_count=0
        for dir in */; do
            if [ -d "$dir" ] && ([ -f "${dir}Containerfile" ] || [ -f "${dir}Dockerfile" ]); then
                subproject_count=$((subproject_count + 1))
            fi
        done

        if [ $subproject_count -eq 0 ]; then
            # Single project in root
            project_name="$(basename $(pwd))"
        else
            # Multiple subprojects detected - this should be handled per-project
            project_name="$(basename $(pwd))"
        fi
    else
        # No Containerfile in root, use current directory name
        project_name="$(basename $(pwd))"
    fi

    # 3. Fallback to current folder basename
    if [ -z "$project_name" ]; then
        project_name="$(basename $(pwd))"
    fi

    echo "$project_name"

# Get full image name with priority logic
# Priority: IMAGE_NAME env var > built from components
_get_image_name tag="":
    #!/usr/bin/env bash
    set -euo pipefail

    tag="{{tag}}"

    # 1. Check IMAGE_NAME environment variable (highest priority)
    if [ -n "${IMAGE_NAME:-}" ]; then
        if [ -n "$tag" ]; then
            echo "${IMAGE_NAME}:$tag"
        else
            echo "$IMAGE_NAME"
        fi
        exit 0
    fi

    # 2. Build from components
    registry="${REGISTRY:-ghcr.io}"
    namespace="${REGISTRY_NAMESPACE:-${GITHUB_USERNAME:-}}"
    project_name=$(just _get_project_name)

    if [ -z "$namespace" ]; then
        echo "Error: REGISTRY_NAMESPACE or GITHUB_USERNAME must be set" >&2
        echo "Set REGISTRY_NAMESPACE in .env file for registry operations" >&2
        exit 1
    fi

    if [ -n "$tag" ]; then
        echo "$registry/$namespace/$project_name:$tag"
    else
        echo "$registry/$namespace/$project_name"
    fi

# Generate default tag based on git or timestamp
_generate_default_tag:
    #!/usr/bin/env bash
    set -euo pipefail

    if git rev-parse --git-dir >/dev/null 2>&1; then
        echo "commit-$(git rev-parse --short HEAD)"
    else
        echo "build-$(date '+%Y%m%d-%H%M%S')"
    fi

# Detect platforms from Containerfile
_detect_platforms containerfile="":
    #!/usr/bin/env bash
    set -euo pipefail

    containerfile="{{containerfile}}"
    default_platforms="${DEFAULT_PLATFORMS:-linux/amd64,linux/arm64}"

    if [ -z "$containerfile" ]; then
        echo "$default_platforms"
        exit 0
    fi

    if [ ! -f "$containerfile" ]; then
        echo "$default_platforms"
        exit 0
    fi

    # Check for --platform specification in FROM statements
    if grep -q "FROM.*--platform" "$containerfile"; then
        # Extract platform from first FROM statement with --platform
        platform=$(grep "FROM.*--platform" "$containerfile" | head -1 | sed -n 's/.*--platform=\([^ ]*\).*/\1/p')
        if [ -n "$platform" ]; then
            echo "$platform"
        else
            echo "$default_platforms"
        fi
    else
        echo "$default_platforms"
    fi

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

    # Check if DOCKER environment variable is set (highest priority)
    if [ -n "${DOCKER:-}" ]; then
        if command -v "$DOCKER" >/dev/null 2>&1; then
            echo "$DOCKER"
            exit 0
        else
            echo "Error: Specified runtime '$DOCKER' not found" >&2
            exit 1
        fi
    fi

    # Auto-detect available runtime
    # Priority: real Docker daemon > podman > docker symlink to podman

    # Check if docker command exists and is NOT a symlink to podman
    if command -v docker >/dev/null 2>&1; then
        docker_path=$(command -v docker)
        # Check if it's a symlink pointing to podman
        if [ -L "$docker_path" ]; then
            docker_target=$(readlink "$docker_path")
            if echo "$docker_target" | grep -q podman; then
                # Docker is symlinked to podman, use podman directly
                if command -v podman >/dev/null 2>&1; then
                    echo "podman"
                    exit 0
                fi
            fi
        else
            # Real docker binary, check if daemon is running
            if docker info >/dev/null 2>&1; then
                echo "docker"
                exit 0
            fi
        fi
    fi

    # Check Podman as fallback
    if command -v podman >/dev/null 2>&1; then
        echo "podman"
        exit 0
    else
        echo "Error: No container runtime available (docker or podman)" >&2
        exit 1
    fi

# Detect compose command based on available and working container runtime
_detect_compose:
    #!/usr/bin/env bash

    # Detect which runtime we're using
    runtime=$(just _detect_runtime 2>/dev/null || echo "none")

    if [ "$runtime" = "podman" ]; then
        # Use podman-compose for podman
        if command -v podman-compose >/dev/null 2>&1; then
            echo "podman-compose"
            exit 0
        else
            echo "Error: Podman detected but podman-compose not available" >&2
            exit 1
        fi
    elif [ "$runtime" = "docker" ]; then
        # Use docker compose for docker
        if docker compose version >/dev/null 2>&1; then
            echo "docker compose"
            exit 0
        elif command -v docker-compose >/dev/null 2>&1; then
            echo "docker-compose"
            exit 0
        else
            echo "Error: Docker is available but no compose tool found" >&2
            exit 1
        fi
    else
        echo "Error: No container runtime detected" >&2
        exit 1
    fi

# Auto-discover compose file in current directory
_discover_compose_file:
    #!/usr/bin/env bash
    # Check common compose file locations in priority order
    if [ -f "compose.yml" ]; then
        echo "compose.yml"
    elif [ -f "compose.yaml" ]; then
        echo "compose.yaml"
    elif [ -f "docker-compose.yml" ]; then
        echo "docker-compose.yml"
    elif [ -f "docker-compose.yaml" ]; then
        echo "docker-compose.yaml"
    elif [ -f "container/compose.dev.yml" ]; then
        echo "container/compose.dev.yml"
    elif [ -f "container/compose.dev.yaml" ]; then
        echo "container/compose.dev.yaml"
    elif [ -f "container/compose.test.yml" ]; then
        echo "container/compose.test.yml"
    elif [ -f "container/compose.test.yaml" ]; then
        echo "container/compose.test.yaml"
    elif [ -f "container/compose.prod.yml" ]; then
        echo "container/compose.prod.yml"
    elif [ -f "container/compose.prod.yaml" ]; then
        echo "container/compose.prod.yaml"
    elif [ -f "container/compose.yml" ]; then
        echo "container/compose.yml"
    elif [ -f "container/compose.yaml" ]; then
        echo "container/compose.yaml"
    elif [ -f "container-compose.yml" ]; then
        echo "container-compose.yml"
    elif [ -f "container-compose.yaml" ]; then
        echo "container-compose.yaml"
    else
        # Fallback: any file named container/compose.*.yml or .yaml
        for f in container/compose.*.yml container/compose.*.yaml; do
            if [ -f "$f" ]; then
                echo "$f"
                exit 0
            fi
        done
        echo ""
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
    docker_is_symlink=false
    if command -v docker >/dev/null 2>&1; then
        if [ -L "$(command -v docker)" ] && readlink "$(command -v docker)" | grep -q podman; then
            docker_is_symlink=true
            echo -e "{{YELLOW}}⚠ Docker command is symlinked to Podman{{NORMAL}}"
            docker_available=false  # Don't count symlink as real docker
        elif docker info >/dev/null 2>&1; then
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
    echo "  RUNTIME SELECTION"
    echo "================================================"

    # Determine which runtime will be used
    detected_runtime=$(just _detect_runtime 2>/dev/null || echo "none")
    detected_compose=$(just _detect_compose 2>/dev/null || echo "none")

    if [ "$detected_runtime" = "podman" ]; then
        echo -e "{{GREEN}}🎯 Using Podman as container runtime{{NORMAL}}"
        if [ "$docker_is_symlink" = true ]; then
            echo -e "{{BLUE}}   (Docker symlink detected, using Podman backend){{NORMAL}}"
        fi
    elif [ "$detected_runtime" = "docker" ]; then
        echo -e "{{GREEN}}🎯 Using Docker as container runtime{{NORMAL}}"
    else
        echo -e "{{RED}}❌ No container runtime available{{NORMAL}}"
    fi

    if [ "$detected_compose" != "none" ]; then
        echo -e "{{GREEN}}✓ Compose tool: $detected_compose{{NORMAL}}"
    else
        echo -e "{{RED}}✗ No compose tool available{{NORMAL}}"
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
