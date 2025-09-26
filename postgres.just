# Universal PostgreSQL database operations

# Execute PostgreSQL SQL query
[group: 'database']
postgres-sql query service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    query="{{query}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$query" ]; then
        echo "Error: SQL query is required" >&2
        echo "Usage: just postgres-sql \"SELECT version();\"" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Executing PostgreSQL query in service: $service{{NC}}"
    echo -e "{{YELLOW}}Query: $query{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "psql -U postgres -c \"$query\"" "$file_arg"
    else
        just exec "$service" "psql -U postgres -c \"$query\""
    fi

# Check PostgreSQL connection and status
[group: 'database']
postgres-check service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Checking PostgreSQL status in service: $service{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "pg_isready -U postgres" "$file_arg"
        just exec "$service" "psql -U postgres -c 'SELECT version();'" "$file_arg"
    else
        just exec "$service" "pg_isready -U postgres"
        just exec "$service" "psql -U postgres -c 'SELECT version();'"
    fi

# List PostgreSQL databases
[group: 'database']
postgres-list-databases service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Listing PostgreSQL databases in service: $service{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "psql -U postgres -c '\\l'" "$file_arg"
    else
        just exec "$service" "psql -U postgres -c '\\l'"
    fi

# List PostgreSQL users
postgres-list-users service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Listing PostgreSQL users in service: $service{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "psql -U postgres -c '\\du'" "$file_arg"
    else
        just exec "$service" "psql -U postgres -c '\\du'"
    fi

# Create PostgreSQL database
postgres-create-database database service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    database="{{database}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$database" ]; then
        echo "Error: Database name is required" >&2
        echo "Usage: just postgres-create-database mydb" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Creating PostgreSQL database: $database{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "createdb -U postgres \"$database\"" "$file_arg"
    else
        just exec "$service" "createdb -U postgres \"$database\""
    fi

# Drop PostgreSQL database
postgres-drop-database database service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    database="{{database}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$database" ]; then
        echo "Error: Database name is required" >&2
        echo "Usage: just postgres-drop-database mydb" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{YELLOW}}WARNING: This will permanently delete database: $database{{NC}}"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "{{BLUE}}Dropping PostgreSQL database: $database{{NC}}"

        if [ -n "$file_arg" ]; then
            just exec "$service" "dropdb -U postgres \"$database\"" "$file_arg"
        else
            just exec "$service" "dropdb -U postgres \"$database\""
        fi
    else
        echo "Operation cancelled"
    fi

# PostgreSQL interactive shell
postgres-shell service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Opening PostgreSQL interactive shell in service: $service{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "psql -U postgres" "$file_arg"
    else
        just exec "$service" "psql -U postgres"
    fi

# Restore PostgreSQL database from backup file
[group: 'database']
postgres-restore backup_file service="postgres" compose-file="" backup_path="./backups":
    #!/usr/bin/env bash
    set -euo pipefail

    backup_file="{{backup_file}}"
    service="{{service}}"
    compose_file="{{compose-file}}"
    backup_path="{{backup_path}}"

    if [ -z "$backup_file" ]; then
        echo "Error: Backup file name is required" >&2
        echo "Usage: just postgres-restore backup_file.sql" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    # Check if backup file exists
    if [ ! -f "$backup_path/$backup_file" ]; then
        echo -e "{{RED}}Error: Backup file '$backup_path/$backup_file' not found{{NC}}" >&2
        echo -e "{{YELLOW}}Available backups:{{NC}}"
        ls -la "$backup_path/" 2>/dev/null || echo "No backups directory found at $backup_path"
        exit 1
    fi

    # Display backup file info
    echo -e "{{BLUE}}Backup file information:{{NC}}"
    echo -e "{{YELLOW}}File:{{NC}} $backup_path/$backup_file"
    echo -e "{{YELLOW}}Size:{{NC}} $(du -h "$backup_path/$backup_file" | cut -f1)"
    echo -e "{{YELLOW}}Modified:{{NC}} $(stat -c %y "$backup_path/$backup_file" 2>/dev/null || stat -f %Sm "$backup_path/$backup_file")"
    echo ""

    # Detect backup type
    if [[ "$backup_file" == *.gz ]]; then
        backup_type="gzipped SQL"
        echo -e "{{BLUE}}Backup type:{{NC}} $backup_type"
    else
        backup_type="plain SQL"
        echo -e "{{BLUE}}Backup type:{{NC}} $backup_type"
    fi

    echo -e "{{BLUE}}Target service:{{NC}} $service"
    echo ""

    echo -e "{{RED}}⚠️  WARNING: This will OVERWRITE the current database!{{NC}}"
    echo -e "{{YELLOW}}This action will replace all data in the target database{{NC}}"
    echo -e "{{YELLOW}}Make sure you have a backup of current data if needed{{NC}}"
    echo ""

    read -p "Are you sure you want to restore from '$backup_file'? Type 'yes' to continue: " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Restore cancelled"
        exit 1
    fi

    echo -e "{{BLUE}}Restoring database from $backup_file...{{NC}}"

    # Copy backup file to container and restore
    if [[ "$backup_file" == *.gz ]]; then
        # For gzipped files
        if [ -n "$file_arg" ]; then
            just exec "$service" "gunzip -c /backups/$backup_file | psql -U postgres" "$file_arg"
        else
            just exec "$service" "gunzip -c /backups/$backup_file | psql -U postgres"
        fi
    else
        # For plain SQL files
        if [ -n "$file_arg" ]; then
            just exec "$service" "psql -U postgres < /backups/$backup_file" "$file_arg"
        else
            just exec "$service" "psql -U postgres < /backups/$backup_file"
        fi
    fi

    echo -e "{{GREEN}}✓ Database restored successfully from $backup_file{{NC}}"