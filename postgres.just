# Universal PostgreSQL database operations

# Execute PostgreSQL SQL query
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