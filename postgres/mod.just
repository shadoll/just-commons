# Universal PostgreSQL database operations

# Define custom colors not in Just's native set
DARK_GREY := '\033[2m'   # Dark grey (dim) for optional parameters

alias help := default

# Default recipe - show available commands
[no-cd]
[private]
default:
    #!/usr/bin/env bash
    echo "{{BOLD}}PostgreSQL Management Commands{{NORMAL}}"
    echo ""
    echo "{{BOLD}}Usage:{{NORMAL}}"
    echo "  just postgres <command> [parameters]"
    echo ""
    echo "{{BOLD}}Parameters:{{NORMAL}}"
    echo -e "  {{YELLOW}}<required>{{NORMAL}}   - Required parameter"
    echo -e "  {{DARK_GREY}}[optional]{{NORMAL}}   - Optional parameter"
    echo ""
    echo -e "  {{DARK_GREY}}[service]{{NORMAL}}      - Service name (default: postgres)"
    echo -e "  {{DARK_GREY}}[compose-file]{{NORMAL}} - Path to compose file"
    echo ""
    echo "{{BOLD}}Commands:{{NORMAL}}"
    echo -e "  {{CYAN}}{{BOLD}}check{{NORMAL}}              {{DARK_GREY}}[service] [compose-file]\033[0m           - Check connection and status"
    echo -e "  {{CYAN}}{{BOLD}}sql{{NORMAL}}                {{YELLOW}}<query>{{NORMAL}} {{DARK_GREY}}[service] [compose-file]\033[0m  - Execute SQL query"
    echo -e "  {{CYAN}}{{BOLD}}shell{{NORMAL}}              {{DARK_GREY}}[service] [compose-file]\033[0m           - Open interactive shell"
    echo -e "  {{CYAN}}{{BOLD}}list-databases{{NORMAL}}     {{DARK_GREY}}[service] [compose-file]\033[0m           - List all databases"
    echo -e "  {{CYAN}}{{BOLD}}list-users{{NORMAL}}         {{DARK_GREY}}[service] [compose-file]\033[0m           - List all users"
    echo -e "  {{CYAN}}{{BOLD}}create-database{{NORMAL}}    {{YELLOW}}<database>{{NORMAL}} {{DARK_GREY}}[service] [compose-file]\033[0m - Create database"
    echo -e "  {{CYAN}}{{BOLD}}drop-database{{NORMAL}}      {{YELLOW}}<database>{{NORMAL}} {{DARK_GREY}}[service] [compose-file]\033[0m - Drop database (with confirmation)"
    echo -e "  {{CYAN}}{{BOLD}}restore{{NORMAL}}            {{YELLOW}}<backup_file>{{NORMAL}} {{DARK_GREY}}[service] [compose-file] [backup_path]\033[0m - Restore from backup"
    echo ""
    echo "{{RED}}⚠️  WARNING: drop-database and restore are DESTRUCTIVE operations!{{NORMAL}}"
    echo ""
    echo "{{BOLD}}Examples:{{NORMAL}}"
    echo "  just postgres check                     # Check PostgreSQL status"
    echo "  just postgres sql \"SELECT version();\"   # Execute SQL query"
    echo "  just postgres shell                     # Open interactive shell"
    echo "  just postgres list-databases            # List all databases"
    echo "  just postgres create-database mydb      # Create new database"
    echo "  just postgres restore backup.sql        # Restore from backup"
    echo ""

# Execute PostgreSQL SQL query
sql query service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    query="{{query}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$query" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} SQL query is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just postgres sql \"SELECT version();\"" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Executing PostgreSQL query in service: $service{{NORMAL}}"
    echo -e "{{YELLOW}}Query: $query{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "psql -U postgres -c \"$query\"" "$file_arg"
    else
        just exec "$service" "psql -U postgres -c \"$query\""
    fi

# Check PostgreSQL connection and status
check service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Checking PostgreSQL status in service: $service{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "pg_isready -U postgres" "$file_arg"
        just exec "$service" "psql -U postgres -c 'SELECT version();'" "$file_arg"
    else
        just exec "$service" "pg_isready -U postgres"
        just exec "$service" "psql -U postgres -c 'SELECT version();'"
    fi

# List PostgreSQL databases
list-databases service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Listing PostgreSQL databases in service: $service{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "psql -U postgres -c '\\l'" "$file_arg"
    else
        just exec "$service" "psql -U postgres -c '\\l'"
    fi

# List PostgreSQL users
list-users service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Listing PostgreSQL users in service: $service{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "psql -U postgres -c '\\du'" "$file_arg"
    else
        just exec "$service" "psql -U postgres -c '\\du'"
    fi

# Create PostgreSQL database
create-database database service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    database="{{database}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$database" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Database name is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just postgres create-database mydb" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Creating PostgreSQL database: $database{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "createdb -U postgres \"$database\"" "$file_arg"
    else
        just exec "$service" "createdb -U postgres \"$database\""
    fi

# Drop PostgreSQL database
[confirm]
drop-database database service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    database="{{database}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$database" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Database name is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just postgres drop-database mydb" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{YELLOW}}WARNING: This will permanently delete database: $database{{NORMAL}}"
    echo -e "{{BLUE}}Dropping PostgreSQL database: $database{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "dropdb -U postgres \"$database\"" "$file_arg"
    else
        just exec "$service" "dropdb -U postgres \"$database\""
    fi

# PostgreSQL interactive shell
shell service="postgres" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Opening PostgreSQL interactive shell in service: $service{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "psql -U postgres" "$file_arg"
    else
        just exec "$service" "psql -U postgres"
    fi

# Restore PostgreSQL database from backup file
[confirm]
restore backup_file service="postgres" compose-file="" backup_path="./backups":
    #!/usr/bin/env bash
    set -euo pipefail

    backup_file="{{backup_file}}"
    service="{{service}}"
    compose_file="{{compose-file}}"
    backup_path="{{backup_path}}"

    if [ -z "$backup_file" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Backup file name is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just postgres restore backup_file.sql" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    # Check if backup file exists
    if [ ! -f "$backup_path/$backup_file" ]; then
        echo -e "{{RED}}Error: Backup file '$backup_path/$backup_file' not found{{NORMAL}}" >&2
        echo -e "{{YELLOW}}Available backups:{{NORMAL}}"
        ls -la "$backup_path/" 2>/dev/null || echo "No backups directory found at $backup_path"
        exit 1
    fi

    # Display backup file info
    echo -e "{{BLUE}}Backup file information:{{NORMAL}}"
    echo -e "{{YELLOW}}File:{{NORMAL}} $backup_path/$backup_file"
    echo -e "{{YELLOW}}Size:{{NORMAL}} $(du -h "$backup_path/$backup_file" | cut -f1)"
    echo -e "{{YELLOW}}Modified:{{NORMAL}} $(stat -c %y "$backup_path/$backup_file" 2>/dev/null || stat -f %Sm "$backup_path/$backup_file")"
    echo ""

    # Detect backup type
    if [[ "$backup_file" == *.gz ]]; then
        backup_type="gzipped SQL"
        echo -e "{{BLUE}}Backup type:{{NORMAL}} $backup_type"
    else
        backup_type="plain SQL"
        echo -e "{{BLUE}}Backup type:{{NORMAL}} $backup_type"
    fi

    echo -e "{{BLUE}}Target service:{{NORMAL}} $service"
    echo ""

    echo -e "{{RED}}⚠️  WARNING: This will OVERWRITE the current database!{{NORMAL}}"
    echo -e "{{YELLOW}}This action will replace all data in the target database{{NORMAL}}"
    echo -e "{{YELLOW}}Make sure you have a backup of current data if needed{{NORMAL}}"
    echo ""

    echo -e "{{BLUE}}Restoring database from $backup_file...{{NORMAL}}"

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

    echo -e "{{GREEN}}✓ Database restored successfully from $backup_file{{NORMAL}}"