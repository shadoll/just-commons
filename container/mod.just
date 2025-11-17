# Universal container management operations

# Define custom colors not in Just's native set
DARK_GREY := '\033[2m'   # Dark grey (dim) for optional parameters

alias help := default

# Default recipe - show available commands
[no-cd]
[private]
default:
    #!/usr/bin/env bash
    echo "{{BOLD}}Container Management Commands{{NORMAL}}"
    echo ""
    echo "{{BOLD}}Usage:{{NORMAL}}"
    echo "  just container <command> [service] [compose-file]"
    echo ""
    echo "{{BOLD}}Parameters:{{NORMAL}}"
    echo -e "  {{YELLOW}}<required>{{NORMAL}}   - Required parameter"
    echo -e "  {{DARK_GREY}}[optional]{{NORMAL}}   - Optional parameter"
    echo ""
    echo -e "  {{DARK_GREY}}[service]{{NORMAL}}      - Service name (if empty, applies to all services)"
    echo -e "  {{DARK_GREY}}[compose-file]{{NORMAL}} - Path to compose file (if empty, uses default)"
    echo ""
    echo "{{BOLD}}Commands:{{NORMAL}}"
    echo -e "  {{CYAN}}{{BOLD}}start{{NORMAL}}        {{DARK_GREY}}[service] [compose-file]\033[0m       - Start service(s)"
    echo -e "  {{CYAN}}{{BOLD}}stop{{NORMAL}}         {{DARK_GREY}}[service] [compose-file]\033[0m       - Stop service(s)"
    echo -e "  {{CYAN}}{{BOLD}}restart{{NORMAL}}      {{DARK_GREY}}[service] [compose-file]\033[0m       - Restart service(s)"
    echo -e "  {{CYAN}}{{BOLD}}status{{NORMAL}}       {{DARK_GREY}}[service] [compose-file]\033[0m       - Show status"
    echo -e "  {{CYAN}}{{BOLD}}logs{{NORMAL}}         {{DARK_GREY}}[service] [compose-file]\033[0m       - View logs"
    echo -e "  {{CYAN}}{{BOLD}}shell{{NORMAL}}        {{YELLOW}}<service>{{NORMAL}} {{DARK_GREY}}[compose-file]\033[0m       - Open shell"
    echo -e "  {{CYAN}}{{BOLD}}exec{{NORMAL}}         {{YELLOW}}<service> <cmd>{{NORMAL}} {{DARK_GREY}}[compose-file]\033[0m - Execute command"
    echo -e "  {{CYAN}}{{BOLD}}exec-pipe{{NORMAL}}    {{YELLOW}}<service> <cmd>{{NORMAL}} {{DARK_GREY}}[compose-file]\033[0m - Execute with piped input"
    echo ""
    echo "{{BOLD}}Examples:{{NORMAL}}"
    echo "  just container start                    # Start all services"
    echo "  just container start myapp              # Start specific service"
    echo "  just container start \"\" compose.yml     # Start all services with custom compose file"
    echo "  just container start myapp compose.yml  # Start myapp with custom compose file"
    echo "  just container logs myapp               # View logs for myapp"
    echo "  just container shell myapp              # Open shell in myapp"
    echo "  just container status                   # Show all services status"
    echo "  just container status \"\" compose.yml    # Status with custom compose file"
    echo ""
    echo "{{BOLD}}Note:{{NORMAL}} Use empty string \"\" to skip optional parameters when providing later ones"
    echo ""

# Start service (or all services if no service specified)
[no-cd]
start service="" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_cmd=$(just _detect_compose)
    service="{{service}}"
    compose_file="{{compose-file}}"

    # Auto-discover compose file if not provided
    if [ -z "$compose_file" ]; then
        compose_file=$(just _discover_compose_file)
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Starting service: $service{{NORMAL}}"
        if ! $compose_cmd $file_arg up -d "$service" 2>&1; then
            echo -e "{{RED}}✗ Service '$service' not found{{NORMAL}}"
            echo ""
            echo -e "{{YELLOW}}Available services:{{NORMAL}}"
            $compose_cmd $file_arg config --services 2>/dev/null || echo "Could not list services"
            exit 1
        fi
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

    # Auto-discover compose file if not provided
    if [ -z "$compose_file" ]; then
        compose_file=$(just _discover_compose_file)
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Stopping service: $service{{NORMAL}}"
        if ! $compose_cmd $file_arg stop "$service" 2>&1; then
            echo -e "{{RED}}✗ Service '$service' not found{{NORMAL}}"
            echo ""
            echo -e "{{YELLOW}}Available services:{{NORMAL}}"
            $compose_cmd $file_arg config --services 2>/dev/null || echo "Could not list services"
            exit 1
        fi
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

    # Auto-discover compose file if not provided
    if [ -z "$compose_file" ]; then
        compose_file=$(just _discover_compose_file)
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Restarting service: $service{{NORMAL}}"
        if ! $compose_cmd $file_arg restart "$service" 2>&1; then
            echo -e "{{RED}}✗ Service '$service' not found{{NORMAL}}"
            echo ""
            echo -e "{{YELLOW}}Available services:{{NORMAL}}"
            $compose_cmd $file_arg config --services 2>/dev/null || echo "Could not list services"
            exit 1
        fi
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

    # Auto-discover compose file if not provided
    if [ -z "$compose_file" ]; then
        compose_file=$(just _discover_compose_file)
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    if [ -n "$service" ]; then
        echo -e "{{BLUE}}Status for: $service{{NORMAL}}"
        # Filter output for specific service
        $compose_cmd $file_arg ps | grep -E "(NAME|$service)" || echo "Service $service not found"
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

    # Auto-discover compose file if not provided
    if [ -z "$compose_file" ]; then
        compose_file=$(just _discover_compose_file)
    fi

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

    # Auto-discover compose file if not provided
    if [ -z "$compose_file" ]; then
        compose_file=$(just _discover_compose_file)
    fi

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

    # Auto-discover compose file if not provided
    if [ -z "$compose_file" ]; then
        compose_file=$(just _discover_compose_file)
    fi

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

    # Auto-discover compose file if not provided
    if [ -z "$compose_file" ]; then
        compose_file=$(just _discover_compose_file)
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    echo -e "{{BLUE}}Executing in $service (with piped input): $cmd{{NORMAL}}"
    $compose_cmd $file_arg exec -T "$service" bash -c "$cmd"
