# Universal container management operations

# Start service (or all services if no service specified)
[no-cd]
start service="" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Starting service: $service{{NORMAL}}"
        $compose_cmd $file_arg up -d "$service"
        echo -e "{{GREEN}}✓ Service $service started{{NORMAL}}"
    else
        echo -e "{{BLUE}}Starting all services...{{NORMAL}}"
        $compose_cmd $file_arg up -d
        echo -e "{{GREEN}}✓ All services started{{NORMAL}}"
    fi

# Stop service (or all services if no service specified)
[no-cd]
stop service="" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Stopping service: $service{{NORMAL}}"
        $compose_cmd $file_arg stop "$service"
        echo -e "{{GREEN}}✓ Service $service stopped{{NORMAL}}"
    else
        echo -e "{{BLUE}}Stopping all services...{{NORMAL}}"
        $compose_cmd $file_arg down
        echo -e "{{GREEN}}✓ All services stopped{{NORMAL}}"
    fi

# Restart service (or all services if no service specified)
[no-cd]
restart service="" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Restarting service: $service{{NORMAL}}"
        $compose_cmd $file_arg restart "$service"
        echo -e "{{GREEN}}✓ Service $service restarted{{NORMAL}}"
    else
        just container stop "$service" "$compose_file"
        just container start "$service" "$compose_file"
    fi

# Show service status (specific service or all)
[no-cd]
status service="" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Status for: $service{{NORMAL}}"
        $compose_cmd $file_arg ps "$service"
    else
        echo -e "{{BLUE}}Service Status:{{NORMAL}}"
        $compose_cmd $file_arg ps
    fi

# View logs for specific service or all services
[no-cd]
logs service="" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Showing logs for: $service{{NORMAL}}"
        $compose_cmd $file_arg logs -f "$service"
    else
        echo -e "{{BLUE}}Showing logs for all services{{NORMAL}}"
        $compose_cmd $file_arg logs -f
    fi

# Open shell in specific container
[no-cd]
shell service compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    echo -e "{{BLUE}}Opening shell in: $service{{NORMAL}}"
    $compose_cmd $file_arg exec "$service" /bin/bash

# Execute command in specific service container
[no-cd]
exec service cmd compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"
    cmd="{{cmd}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    echo -e "{{BLUE}}Executing in $service: $cmd{{NORMAL}}"
    $compose_cmd $file_arg exec "$service" bash -c "$cmd"

# Execute command in specific service container with piped input support
[no-cd]
exec-pipe service cmd compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"
    cmd="{{cmd}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    echo -e "{{BLUE}}Executing in $service (with piped input): $cmd{{NORMAL}}"
    $compose_cmd $file_arg exec -T "$service" bash -c "$cmd"