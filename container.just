# Universal container management operations

# Start service (or all services if no service specified)
[group('container')]
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
        echo -e "{{BLUE}}Starting service: $service{{NC}}"
        $compose_cmd $file_arg up -d "$service"
        echo -e "{{GREEN}}✓ Service $service started{{NC}}"
    else
        echo -e "{{BLUE}}Starting all services...{{NC}}"
        $compose_cmd $file_arg up -d
        echo -e "{{GREEN}}✓ All services started{{NC}}"
    fi

# Stop service (or all services if no service specified)
[group('container')]
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
        echo -e "{{BLUE}}Stopping service: $service{{NC}}"
        $compose_cmd $file_arg stop "$service"
        echo -e "{{GREEN}}✓ Service $service stopped{{NC}}"
    else
        echo -e "{{BLUE}}Stopping all services...{{NC}}"
        $compose_cmd $file_arg down
        echo -e "{{GREEN}}✓ All services stopped{{NC}}"
    fi

# Restart service (or all services if no service specified)
[group('container')]
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
        echo -e "{{BLUE}}Restarting service: $service{{NC}}"
        $compose_cmd $file_arg restart "$service"
        echo -e "{{GREEN}}✓ Service $service restarted{{NC}}"
    else
        just stop "$service" "$compose_file"
        just start "$service" "$compose_file"
    fi

# Show service status (specific service or all)
[group('container')]
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
        echo -e "{{BLUE}}Status for: $service{{NC}}"
        $compose_cmd $file_arg ps "$service"
    else
        echo -e "{{BLUE}}Service Status:{{NC}}"
        $compose_cmd $file_arg ps
    fi

# View logs for specific service or all services
[group('container')]
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
        echo -e "{{BLUE}}Showing logs for: $service{{NC}}"
        $compose_cmd $file_arg logs -f "$service"
    else
        echo -e "{{BLUE}}Showing logs for all services{{NC}}"
        $compose_cmd $file_arg logs -f
    fi

# Open shell in specific container
[group('container')]
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

    echo -e "{{BLUE}}Opening shell in: $service{{NC}}"
    $compose_cmd $file_arg exec "$service" /bin/bash

# Execute command in specific service container
[group('container')]
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

    echo -e "{{BLUE}}Executing in $service: $cmd{{NC}}"
    $compose_cmd $file_arg exec "$service" bash -c "$cmd"