# Core utilities shared across all just-commons modules

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
env-check:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'

    echo "================================================"
    echo "  Container Environment Detection"
    echo "================================================"
    echo ""

    # Check Docker
    if command -v docker >/dev/null 2>&1; then
        if docker info >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Docker Engine detected and running${NC}"
            docker_available=true
        else
            echo -e "${YELLOW}⚠ Docker is installed but daemon is not running${NC}"
            docker_available=false
        fi
    else
        echo -e "${RED}✗ Docker not found${NC}"
        docker_available=false
    fi

    # Check Podman
    if command -v podman >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Podman detected${NC}"
        podman_available=true
    else
        echo -e "${RED}✗ Podman not found${NC}"
        podman_available=false
    fi

    echo ""
    echo "================================================"
    echo "  SUMMARY"
    echo "================================================"

    if [ "$docker_available" = true ] || [ "$podman_available" = true ]; then
        echo -e "${GREEN}🎉 Container runtime available!${NC}"
        echo ""
        echo "You can use these universal commands:"
        echo "  just build <project>        # Build any project image"
        echo "  just start <service>        # Start any service"
        echo "  just registry-login         # Login to registry"
    else
        echo -e "${RED}❌ No container runtime available${NC}"
        echo ""
        echo "Please install Docker or Podman:"
        echo "  • Docker: https://docs.docker.com/get-docker/"
        echo "  • Podman: https://podman.io/getting-started/installation"
    fi