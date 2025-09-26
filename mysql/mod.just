# Universal MySQL database operations

# Execute MySQL SQL query
[group('database')]
sql query service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    query="{{query}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$query" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} SQL query is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just mysql sql \"SELECT VERSION();\"" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Executing MySQL query in service: $service{{NORMAL}}"
    echo -e "{{YELLOW}}Query: $query{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"$query\"" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"$query\""
    fi

# Check MySQL connection and status
[group('database')]
check service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Checking MySQL status in service: $service{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysqladmin -u root -p\${MYSQL_ROOT_PASSWORD} ping" "$file_arg"
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SELECT VERSION();'" "$file_arg"
    else
        just exec "$service" "mysqladmin -u root -p\${MYSQL_ROOT_PASSWORD} ping"
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SELECT VERSION();'"
    fi

# List MySQL databases
[group('database')]
list-databases service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Listing MySQL databases in service: $service{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SHOW DATABASES;'" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SHOW DATABASES;'"
    fi

# List MySQL users
[group('database')]
list-users service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Listing MySQL users in service: $service{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SELECT User, Host FROM mysql.user;'" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SELECT User, Host FROM mysql.user;'"
    fi

# Create MySQL database
[group('database')]
create-database database service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    database="{{database}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$database" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Database name is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just mysql create-database mydb" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Creating MySQL database: $database{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'CREATE DATABASE \`$database\`;'" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'CREATE DATABASE \`$database\`;'"
    fi

# Drop MySQL database
[group('database')]
[confirm]
drop-database database service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    database="{{database}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$database" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Database name is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just mysql drop-database mydb" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{YELLOW}}WARNING: This will permanently delete database: $database{{NORMAL}}"
    echo -e "{{BLUE}}Dropping MySQL database: $database{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'DROP DATABASE \`$database\`;'" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'DROP DATABASE \`$database\`;'"
    fi

# Create MySQL user
[group('database')]
create-user username password service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    username="{{username}}"
    password="{{password}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$username" ] || [ -z "$password" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Username and password are required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just mysql create-user myuser mypassword" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Creating MySQL user: $username{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"CREATE USER '$username'@'%' IDENTIFIED BY '$password';\"" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"CREATE USER '$username'@'%' IDENTIFIED BY '$password';\""
    fi

# Grant MySQL privileges
[group('database')]
grant-privileges database username service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    database="{{database}}"
    username="{{username}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$database" ] || [ -z "$username" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Database and username are required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just mysql grant-privileges mydb myuser" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Granting privileges on $database to $username{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"GRANT ALL PRIVILEGES ON \\\`$database\\\`.* TO '$username'@'%'; FLUSH PRIVILEGES;\"" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"GRANT ALL PRIVILEGES ON \\\`$database\\\`.* TO '$username'@'%'; FLUSH PRIVILEGES;\""
    fi

# MySQL interactive shell
[group('database')]
shell service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Opening MySQL interactive shell in service: $service{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD}" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD}"
    fi

# Restore MySQL database from backup file
[group('database')]
[confirm]
restore backup_file database service="mysql" compose-file="" backup_path="./backups":
    #!/usr/bin/env bash
    set -euo pipefail

    backup_file="{{backup_file}}"
    database="{{database}}"
    service="{{service}}"
    compose_file="{{compose-file}}"
    backup_path="{{backup_path}}"

    if [ -z "$backup_file" ] || [ -z "$database" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Backup file and database name are required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just mysql restore backup_file.sql database_name" >&2
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

    echo -e "{{BLUE}}Target database:{{NORMAL}} $database"
    echo -e "{{BLUE}}Target service:{{NORMAL}} $service"
    echo ""

    echo -e "{{RED}}⚠️  WARNING: This will OVERWRITE the current database!{{NORMAL}}"
    echo -e "{{YELLOW}}This action will replace all data in '$database' database{{NORMAL}}"
    echo -e "{{YELLOW}}Make sure you have a backup of current data if needed{{NORMAL}}"
    echo ""

    echo -e "{{BLUE}}Restoring database '$database' from $backup_file...{{NORMAL}}"

    # Restore database from backup file
    if [[ "$backup_file" == *.gz ]]; then
        # For gzipped files
        if [ -n "$file_arg" ]; then
            just exec "$service" "gunzip -c /backups/$backup_file | mysql -u root -p\${MYSQL_ROOT_PASSWORD} $database" "$file_arg"
        else
            just exec "$service" "gunzip -c /backups/$backup_file | mysql -u root -p\${MYSQL_ROOT_PASSWORD} $database"
        fi
    else
        # For plain SQL files
        if [ -n "$file_arg" ]; then
            just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} $database < /backups/$backup_file" "$file_arg"
        else
            just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} $database < /backups/$backup_file"
        fi
    fi

    echo -e "{{GREEN}}✓ Database '$database' restored successfully from $backup_file{{NORMAL}}"