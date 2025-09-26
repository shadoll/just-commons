# Universal container management operations

# Start service (or all services if no service specified)
start service="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Starting service: $service{{NC}}"
        $compose_cmd -f compose.yml up -d "$service"
        echo -e "{{GREEN}}✓ Service $service started{{NC}}"
    else
        echo -e "{{BLUE}}Starting all services...{{NC}}"
        $compose_cmd -f compose.yml up -d
        echo -e "{{GREEN}}✓ All services started{{NC}}"
    fi

# Stop service (or all services if no service specified)
stop service="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Stopping service: $service{{NC}}"
        $compose_cmd -f compose.yml stop "$service"
        echo -e "{{GREEN}}✓ Service $service stopped{{NC}}"
    else
        echo -e "{{BLUE}}Stopping all services...{{NC}}"
        $compose_cmd -f compose.yml down
        echo -e "{{GREEN}}✓ All services stopped{{NC}}"
    fi

# Restart service (or all services if no service specified)
restart service="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Restarting service: $service{{NC}}"
        $compose_cmd -f compose.yml restart "$service"
        echo -e "{{GREEN}}✓ Service $service restarted{{NC}}"
    else
        just stop
        just start
    fi

# Show service status (specific service or all)
status service="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Status for: $service{{NC}}"
        $compose_cmd -f compose.yml ps "$service"
    else
        echo -e "{{BLUE}}Service Status:{{NC}}"
        $compose_cmd -f compose.yml ps
    fi

# View logs for specific service or all services
logs service="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Showing logs for: $service{{NC}}"
        $compose_cmd -f compose.yml logs -f "$service"
    else
        echo -e "{{BLUE}}Showing logs for all services{{NC}}"
        $compose_cmd -f compose.yml logs -f
    fi

# Open shell in specific container
shell service:
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"

    echo -e "{{BLUE}}Opening shell in: $service{{NC}}"
    $compose_cmd -f compose.yml exec "$service" /bin/bash

# Execute command in specific service container
exec service cmd:
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"
    cmd="{{cmd}}"

    echo -e "{{BLUE}}Executing in $service: $cmd{{NC}}"
    $compose_cmd -f compose.yml exec "$service" bash -c "$cmd"

# Pull latest images for specific service or all services
pull service="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Pulling image for: $service{{NC}}"
        $compose_cmd -f compose.yml pull "$service"
        echo -e "{{GREEN}}✓ Image updated for $service{{NC}}"
    else
        echo -e "{{BLUE}}Pulling all images...{{NC}}"
        $compose_cmd -f compose.yml pull
        echo -e "{{GREEN}}✓ All images updated{{NC}}"
    fi