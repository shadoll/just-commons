# Additional helper commands for service management

# Environment detection
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
        echo "You can use these commands:"
        echo "  just build postgres     # Build PostgreSQL image"
        echo "  just build servapp      # Build ServApp image"
        echo "  just login              # Login to registry"
    else
        echo -e "${RED}❌ No container runtime available${NC}"
        echo ""
        echo "Please install Docker or Podman:"
        echo "  • Docker: https://docs.docker.com/get-docker/"
        echo "  • Podman: https://podman.io/getting-started/installation"
    fi

# Start service (helper command)
start service:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m'

    service="{{service}}"
    runtime=$(just _detect_runtime)

    if [ ! -d "$service" ]; then
        echo "Error: Service directory '$service' not found" >&2
        exit 1
    fi

    echo -e "${BLUE}Starting $service service...${NC}"
    cd "$service"

    # Detect compose command based on available and working container runtime
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        # Docker daemon is running, check for compose
        if docker compose version >/dev/null 2>&1; then
            docker compose up -d
        elif command -v docker-compose >/dev/null 2>&1; then
            docker-compose up -d
        else
            echo "Error: Docker is running but no compose tool found" >&2
            exit 1
        fi
    elif command -v podman >/dev/null 2>&1 && command -v podman-compose >/dev/null 2>&1; then
        podman-compose up -d
    else
        echo "Error: No working container runtime with compose tool found" >&2
        exit 1
    fi

    echo -e "${GREEN}✓ $service service started${NC}"

# Stop service (helper command)
stop service:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m'

    service="{{service}}"

    if [ ! -d "$service" ]; then
        echo "Error: Service directory '$service' not found" >&2
        exit 1
    fi

    echo -e "${BLUE}Stopping $service service...${NC}"
    cd "$service"

    # Detect compose command based on available and working container runtime
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        # Docker daemon is running, check for compose
        if docker compose version >/dev/null 2>&1; then
            docker compose down
        elif command -v docker-compose >/dev/null 2>&1; then
            docker-compose down
        else
            echo "Error: Docker is running but no compose tool found" >&2
            exit 1
        fi
    elif command -v podman >/dev/null 2>&1 && command -v podman-compose >/dev/null 2>&1; then
        podman-compose down
    else
        echo "Error: No working container runtime with compose tool found" >&2
        exit 1
    fi

    echo -e "${GREEN}✓ $service service stopped${NC}"

# Show service logs (helper command)
logs service:
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"

    if [ ! -d "$service" ]; then
        echo "Error: Service directory '$service' not found" >&2
        exit 1
    fi

    cd "$service"

    # Detect compose command based on available and working container runtime
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        # Docker daemon is running, check for compose
        if docker compose version >/dev/null 2>&1; then
            docker compose logs -f
        elif command -v docker-compose >/dev/null 2>&1; then
            docker-compose logs -f
        else
            echo "Error: Docker is running but no compose tool found" >&2
            exit 1
        fi
    elif command -v podman >/dev/null 2>&1 && command -v podman-compose >/dev/null 2>&1; then
        podman-compose logs -f
    else
        echo "Error: No working container runtime with compose tool found" >&2
        exit 1
    fi

# Open shell in running container (helper command)
shell service:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    RED='\033[0;31m'
    NC='\033[0m'

    service="{{service}}"
    runtime=$(just _detect_runtime)

    # Get first running container for this service
    container_id=$($runtime ps -q --filter "label=com.docker.compose.project=$service" | head -n1)
    if [ -n "$container_id" ]; then
        $runtime exec -it "$container_id" /bin/bash || \
        $runtime exec -it "$container_id" /bin/sh
    else
        echo -e "${RED}No running containers found for $service${NC}"
        echo "Start the service first with: just start $service"
        exit 1
    fi

# Execute command in service container (helper command)
exec service cmd:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    RED='\033[0;31m'
    NC='\033[0m'

    service="{{service}}"
    command="{{cmd}}"
    runtime=$(just _detect_runtime)

    if [ -z "$command" ]; then
        echo -e "${RED}No command specified${NC}" >&2
        echo "Usage: just exec $service \"command to execute\"" >&2
        exit 1
    fi

    # Get first running container for this service
    container_id=$($runtime ps -q --filter "label=com.docker.compose.project=$service" | head -n1)
    if [ -n "$container_id" ]; then
        $runtime exec -it "$container_id" sh -c "$command"
    else
        echo -e "${RED}No running containers found for $service${NC}"
        echo "Start the service first with: just start $service"
        exit 1
    fi

# Show service status (helper command)
status service:
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"

    if [ ! -d "$service" ]; then
        echo "Error: Service directory '$service' not found" >&2
        exit 1
    fi

    cd "$service"

    # Detect compose command based on available and working container runtime
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        # Docker daemon is running, check for compose
        if docker compose version >/dev/null 2>&1; then
            docker compose ps
        elif command -v docker-compose >/dev/null 2>&1; then
            docker-compose ps
        else
            echo "Error: Docker is running but no compose tool found" >&2
            exit 1
        fi
    elif command -v podman >/dev/null 2>&1 && command -v podman-compose >/dev/null 2>&1; then
        podman-compose ps
    else
        echo "Error: No working container runtime with compose tool found" >&2
        exit 1
    fi


# Quick development setup
dev-setup:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'

    echo -e "${BLUE}Setting up development environment...${NC}"

    # Check environment
    just env-check

    echo ""
    echo -e "${BLUE}Building development images...${NC}"

    # Build development images
    just postgres-dev
    just servapp-dev

    echo ""
    echo -e "${GREEN}✓ Development environment ready!${NC}"
    echo ""
    echo -e "${YELLOW}Available commands:${NC}"
    echo "  just start postgres    # Start PostgreSQL service"
    echo "  just start servapp     # Start ServApp service"
    echo "  just logs postgres     # View PostgreSQL logs"
    echo "  just shell postgres    # Connect to PostgreSQL container"

# Clean all development artifacts
dev-clean:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'

    echo -e "${BLUE}Cleaning development environment...${NC}"

    runtime=$(just _detect_runtime)

    # Stop any running services
    echo -e "${YELLOW}Stopping services...${NC}"
    just stop postgres 2>/dev/null || true
    just stop servapp 2>/dev/null || true

    # Clean images
    echo -e "${YELLOW}Cleaning development images...${NC}"
    just clean postgres 2>/dev/null || true
    just clean servapp 2>/dev/null || true

    # Remove dev tags
    $runtime rmi postgres:dev servapp:dev 2>/dev/null || true

    echo -e "${GREEN}✓ Development environment cleaned${NC}"