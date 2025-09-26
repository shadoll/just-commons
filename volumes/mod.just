# Universal volume management operations

# Clean all volumes used by compose file (DESTRUCTIVE!)
[group('volumes')]
[confirm]
clean-all compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    compose_file="{{compose-file}}"
    compose_cmd=$(just _detect_compose)

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="-f $compose_file"
    fi

    echo -e "{{RED}}⚠️  WARNING: This will DELETE ALL DATA!{{NORMAL}}"
    echo -e "{{YELLOW}}This will remove all volumes defined in the compose file{{NORMAL}}"

    # Show which volumes would be removed
    echo -e "{{BLUE}}Volumes that will be removed:{{NORMAL}}"
    $compose_cmd $file_arg config --volumes 2>/dev/null || echo "Cannot list volumes from compose file"
    echo ""

    echo -e "{{BLUE}}Stopping services...{{NORMAL}}"
    $compose_cmd $file_arg down

    echo -e "{{BLUE}}Removing volumes...{{NORMAL}}"
    $compose_cmd $file_arg down -v

    echo -e "{{GREEN}}✓ All volumes removed{{NORMAL}}"

# Remove specific volume by name (DESTRUCTIVE!)
[group('volumes')]
[confirm]
remove volume_name:
    #!/usr/bin/env bash
    set -euo pipefail

    volume_name="{{volume_name}}"

    if [ -z "$volume_name" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Volume name is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just volumes remove my_volume_name" >&2
        exit 1
    fi

    runtime=$(just _detect_runtime)

    # Check if volume exists
    if ! $runtime volume ls --format "table {{{{.Name}}}}" | grep -q "^${volume_name}$"; then
        echo -e "{{YELLOW}}Volume '$volume_name' does not exist{{NORMAL}}"
        exit 0
    fi

    echo -e "{{RED}}⚠️  WARNING: This will DELETE VOLUME DATA!{{NORMAL}}"
    echo -e "{{YELLOW}}This will remove volume: $volume_name{{NORMAL}}"

    echo -e "{{BLUE}}Removing volume: $volume_name{{NORMAL}}"
    $runtime volume rm "$volume_name" 2>/dev/null || true

    echo -e "{{GREEN}}✓ Volume '$volume_name' removed{{NORMAL}}"

# Remove volumes matching pattern (DESTRUCTIVE!)
[group('volumes')]
[confirm]
remove-pattern pattern:
    #!/usr/bin/env bash
    set -euo pipefail

    pattern="{{pattern}}"

    if [ -z "$pattern" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Volume pattern is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just volumes remove-pattern 'myproject_*'" >&2
        exit 1
    fi

    runtime=$(just _detect_runtime)

    # Find matching volumes
    matching_volumes=$($runtime volume ls --format "table {{{{.Name}}}}" | grep "$pattern" || true)

    if [ -z "$matching_volumes" ]; then
        echo -e "{{YELLOW}}No volumes found matching pattern: $pattern{{NORMAL}}"
        exit 0
    fi

    echo -e "{{RED}}⚠️  WARNING: This will DELETE VOLUME DATA!{{NORMAL}}"
    echo -e "{{YELLOW}}Volumes matching pattern '$pattern':{{NORMAL}}"
    echo "$matching_volumes"
    echo ""

    echo -e "{{BLUE}}Removing matching volumes...{{NORMAL}}"
    echo "$matching_volumes" | while IFS= read -r volume; do
        if [ -n "$volume" ]; then
            echo "Removing: $volume"
            $runtime volume rm "$volume" 2>/dev/null || true
        fi
    done

    echo -e "{{GREEN}}✓ Matching volumes removed{{NORMAL}}"

# List all volumes or filter by pattern
[group('volumes')]
list pattern="":
    #!/usr/bin/env bash
    set -euo pipefail

    pattern="{{pattern}}"
    runtime=$(just _detect_runtime)

    if [ -n "$pattern" ]; then
        echo -e "{{BLUE}}Volumes matching pattern '$pattern':{{NORMAL}}"
        $runtime volume ls | grep "$pattern" || echo "No volumes found matching pattern: $pattern"
    else
        echo -e "{{BLUE}}All volumes:{{NORMAL}}"
        $runtime volume ls
    fi