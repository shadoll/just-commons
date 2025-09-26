# Universal volume management operations

# Clean all volumes (DESTRUCTIVE!)
[group: 'volumes']
volumes-clean-all project_prefix compose-file="compose.yml":
    #!/usr/bin/env bash
    set -euo pipefail

    project_prefix="{{project_prefix}}"
    compose_file="{{compose-file}}"

    if [ -z "$project_prefix" ]; then
        echo "Error: Project prefix is required" >&2
        echo "Usage: just volumes-clean-all myproject" >&2
        exit 1
    fi

    compose_cmd=$(just _detect_compose)

    echo -e "{{RED}}⚠️  WARNING: This will DELETE ALL DATA!{{NC}}"
    echo -e "{{YELLOW}}This will remove all volumes: postgres_data, postgres_lib, servapp_data, servapp_logs{{NC}}"
    read -p "Are you sure? Type 'yes' to continue: " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Aborted"
        exit 1
    fi

    echo -e "{{BLUE}}Stopping services...{{NC}}"
    $compose_cmd -f "$compose_file" down

    echo -e "{{BLUE}}Removing volumes...{{NC}}"
    $compose_cmd -f "$compose_file" down -v

    echo -e "{{GREEN}}✓ All volumes removed{{NC}}"

# Clean only PostgreSQL data volume (DESTRUCTIVE!)
[group: 'volumes']
volumes-clean-postgres project_prefix:
    #!/usr/bin/env bash
    set -euo pipefail

    project_prefix="{{project_prefix}}"

    if [ -z "$project_prefix" ]; then
        echo "Error: Project prefix is required" >&2
        echo "Usage: just volumes-clean-postgres myproject" >&2
        exit 1
    fi

    runtime=$(just _detect_runtime)

    echo -e "{{RED}}⚠️  WARNING: This will DELETE PostgreSQL DATA!{{NC}}"
    echo -e "{{YELLOW}}This will remove postgres_data and postgres_lib volumes{{NC}}"
    read -p "Are you sure? Type 'yes' to continue: " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Aborted"
        exit 1
    fi

    echo -e "{{BLUE}}Stopping PostgreSQL service...{{NC}}"
    just stop

    echo -e "{{BLUE}}Removing PostgreSQL volumes...{{NC}}"
    $runtime volume rm servass_${project_prefix}_postgres_data servass_${project_prefix}_postgres_lib 2>/dev/null || true

    echo -e "{{GREEN}}✓ PostgreSQL volumes removed{{NC}}"
    echo -e "{{YELLOW}}Run 'just start' to create fresh PostgreSQL instance{{NC}}"

# Clean only ServApp data volume (DESTRUCTIVE!)
[group: 'volumes']
volumes-clean-servapp project_prefix app_container compose-file="compose.yml":
    #!/usr/bin/env bash
    set -euo pipefail

    project_prefix="{{project_prefix}}"
    app_container="{{app_container}}"
    compose_file="{{compose-file}}"

    if [ -z "$project_prefix" ]; then
        echo "Error: Project prefix is required" >&2
        echo "Usage: just volumes-clean-servapp myproject myapp" >&2
        exit 1
    fi

    if [ -z "$app_container" ]; then
        echo "Error: App container name is required" >&2
        echo "Usage: just volumes-clean-servapp myproject myapp" >&2
        exit 1
    fi

    runtime=$(just _detect_runtime)

    echo -e "{{RED}}⚠️  WARNING: This will DELETE ServApp DATA!{{NC}}"
    echo -e "{{YELLOW}}This will remove servapp_data and servapp_logs volumes{{NC}}"
    read -p "Are you sure? Type 'yes' to continue: " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Aborted"
        exit 1
    fi

    echo -e "{{BLUE}}Stopping ServApp service...{{NC}}"
    compose_cmd=$(just _detect_compose)
    $compose_cmd -f "$compose_file" stop "$app_container"

    echo -e "{{BLUE}}Removing ServApp volumes...{{NC}}"
    $runtime volume rm servass_${project_prefix}_servapp_data servass_${project_prefix}_servapp_logs 2>/dev/null || true

    echo -e "{{GREEN}}✓ ServApp volumes removed{{NC}}"
    echo -e "{{YELLOW}}Run 'just start' to recreate ServApp with fresh data{{NC}}"

# List project volumes
[group: 'volumes']
volumes-list project_prefix:
    #!/usr/bin/env bash
    set -euo pipefail

    project_prefix="{{project_prefix}}"

    if [ -z "$project_prefix" ]; then
        echo "Error: Project prefix is required" >&2
        echo "Usage: just volumes-list myproject" >&2
        exit 1
    fi

    runtime=$(just _detect_runtime)

    echo -e "{{BLUE}}Project volumes:{{NC}}"
    $runtime volume ls | grep "servass_${project_prefix}" || echo "No servass_${project_prefix} volumes found"