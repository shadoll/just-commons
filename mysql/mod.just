# Universal MySQL database operations

# Define custom colors not in Just's native set
DARK_GREY := '\033[2m'   # Dark grey (dim) for optional parameters

alias help := default

# Default recipe - show available commands
[no-cd]
[private]
default:
    #!/usr/bin/env bash
    echo "{{BOLD}}MySQL Management Commands{{NORMAL}}"
    echo ""
    echo "{{BOLD}}Usage:{{NORMAL}}"
    echo "  just mysql <command> [parameters]"
    echo ""
    echo "{{BOLD}}Parameters:{{NORMAL}}"
    echo -e "  {{YELLOW}}<required>{{NORMAL}}   - Required parameter"
    echo -e "  {{DARK_GREY}}[optional]{{NORMAL}}   - Optional parameter"
    echo ""
    echo -e "  {{DARK_GREY}}[service]{{NORMAL}}      - Service name (default: mysql)"
    echo -e "  {{DARK_GREY}}[compose-file]{{NORMAL}} - Path to compose file"
    echo ""
    echo "{{BOLD}}Commands:{{NORMAL}}"
    echo -e "  {{CYAN}}{{BOLD}}check{{NORMAL}}              {{DARK_GREY}}[service] [compose-file]\033[0m                              - Check connection and status"
    echo -e "  {{CYAN}}{{BOLD}}sql{{NORMAL}}                {{YELLOW}}<query>{{NORMAL}} {{DARK_GREY}}[service] [compose-file]\033[0m                     - Execute SQL query"
    echo -e "  {{CYAN}}{{BOLD}}shell{{NORMAL}}              {{DARK_GREY}}[service] [compose-file]\033[0m                              - Open interactive shell"
    echo -e "  {{CYAN}}{{BOLD}}list-databases{{NORMAL}}     {{DARK_GREY}}[service] [compose-file]\033[0m                              - List all databases"
    echo -e "  {{CYAN}}{{BOLD}}list-users{{NORMAL}}         {{DARK_GREY}}[service] [compose-file]\033[0m                              - List all users"
    echo -e "  {{CYAN}}{{BOLD}}create-database{{NORMAL}}    {{YELLOW}}<database>{{NORMAL}} {{DARK_GREY}}[service] [compose-file]\033[0m                    - Create database"
    echo -e "  {{CYAN}}{{BOLD}}drop-database{{NORMAL}}      {{YELLOW}}<database>{{NORMAL}} {{DARK_GREY}}[service] [compose-file]\033[0m                    - Drop database (with confirmation)"
    echo -e "  {{CYAN}}{{BOLD}}create-user{{NORMAL}}        {{YELLOW}}<username> <password>{{NORMAL}} {{DARK_GREY}}[service] [compose-file]\033[0m        - Create user"
    echo -e "  {{CYAN}}{{BOLD}}grant-privileges{{NORMAL}}   {{YELLOW}}<database> <username>{{NORMAL}} {{DARK_GREY}}[service] [compose-file]\033[0m        - Grant privileges"
    echo -e "  {{CYAN}}{{BOLD}}backup{{NORMAL}}             {{YELLOW}}<database>{{NORMAL}} {{DARK_GREY}}[service] [compose-file] [backup_path] [name]\033[0m - Create backup"
    echo -e "  {{CYAN}}{{BOLD}}restore{{NORMAL}}            {{YELLOW}}<backup_file> <database>{{NORMAL}} {{DARK_GREY}}[service] [compose-file] [backup_path]\033[0m - Restore from backup"
    echo ""
    echo "{{RED}}⚠️  WARNING: drop-database and restore are DESTRUCTIVE operations!{{NORMAL}}"
    echo ""
    echo "{{BOLD}}Examples:{{NORMAL}}"
    echo "  just mysql check                        # Check MySQL status"
    echo "  just mysql sql \"SELECT VERSION();\"      # Execute SQL query"
    echo "  just mysql shell                        # Open interactive shell"
    echo "  just mysql list-databases               # List all databases"
    echo "  just mysql create-database mydb         # Create new database"
    echo "  just mysql create-user myuser mypass    # Create new user"
    echo "  just mysql grant-privileges mydb myuser # Grant user access to database"
    echo "  just mysql backup mydb                  # Backup database"
    echo "  just mysql restore backup.sql mydb      # Restore from backup"
    echo ""

# Execute MySQL SQL query
[no-cd]
sql query service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    query="{{query}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Executing MySQL query in service: $service{{NORMAL}}"
    echo -e "{{YELLOW}}Query: $query{{NORMAL}}"

    if [ -n "$file_arg" ]; then
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"$query\"" "$file_arg"
    else
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"$query\""
    fi

# Check MySQL connection and status
[no-cd]
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
        just container exec "$service" "mysqladmin -u root -p\${MYSQL_ROOT_PASSWORD} ping" "$file_arg"
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SELECT VERSION();'" "$file_arg"
    else
        just container exec "$service" "mysqladmin -u root -p\${MYSQL_ROOT_PASSWORD} ping"
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SELECT VERSION();'"
    fi

# List MySQL databases
[no-cd]
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
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SHOW DATABASES;'" "$file_arg"
    else
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SHOW DATABASES;'"
    fi

# List MySQL users
[no-cd]
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
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SELECT User, Host FROM mysql.user;'" "$file_arg"
    else
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SELECT User, Host FROM mysql.user;'"
    fi

# Create MySQL database
[no-cd]
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
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'CREATE DATABASE \`$database\`;'" "$file_arg"
    else
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'CREATE DATABASE \`$database\`;'"
    fi

# Drop MySQL database
[confirm]
[no-cd]
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
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'DROP DATABASE \`$database\`;'" "$file_arg"
    else
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'DROP DATABASE \`$database\`;'"
    fi

# Create MySQL user
[no-cd]
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
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"CREATE USER '$username'@'%' IDENTIFIED BY '$password';\"" "$file_arg"
    else
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"CREATE USER '$username'@'%' IDENTIFIED BY '$password';\""
    fi

# Grant MySQL privileges
[no-cd]
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
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"GRANT ALL PRIVILEGES ON \\\`$database\\\`.* TO '$username'@'%'; FLUSH PRIVILEGES;\"" "$file_arg"
    else
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"GRANT ALL PRIVILEGES ON \\\`$database\\\`.* TO '$username'@'%'; FLUSH PRIVILEGES;\""
    fi

# MySQL interactive shell
[no-cd]
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
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD}" "$file_arg"
    else
        just container exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD}"
    fi

# Create MySQL database backup
[no-cd]
backup database service="mysql" compose-file="" backup_path="./backups" backup_name="":
    #!/usr/bin/env bash
    set -euo pipefail

    database="{{database}}"
    service="{{service}}"
    compose_file="{{compose-file}}"
    backup_path="{{backup_path}}"
    backup_name="{{backup_name}}"

    echo -e "{{BLUE}}💾 Creating MySQL database backup...{{NORMAL}}"
    echo -e "{{YELLOW}}Database: $database, Service: $service, Path: $backup_path{{NORMAL}}"

    # Create backup directory
    mkdir -p "$backup_path"

    # Generate backup filename
    if [ -n "$backup_name" ]; then
        backup_file="${backup_path}/${backup_name}.sql.gz"
    else
        timestamp=$(date +%Y%m%d_%H%M%S)
        backup_file="${backup_path}/${database}_${timestamp}.sql.gz"
    fi

    echo -e "{{BLUE}}Creating MySQL backup for database: $database{{NORMAL}}"
    echo -e "{{YELLOW}}Backup file: $backup_file{{NORMAL}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    # Create backup
    if [ -n "$file_arg" ]; then
        just container exec "$service" "mysqldump --single-transaction --routines --triggers -u root -p\${MYSQL_ROOT_PASSWORD} $database" "$file_arg" | gzip > "$backup_file"
    else
        just container exec "$service" "mysqldump --single-transaction --routines --triggers -u root -p\${MYSQL_ROOT_PASSWORD} $database" | gzip > "$backup_file"
    fi

    if [ $? -eq 0 ]; then
        echo -e "{{GREEN}}✓ Database backup completed: $backup_file{{NORMAL}}"
    else
        echo -e "{{RED}}❌ Database backup failed{{NORMAL}}"
        exit 1
    fi

# Restore MySQL database from backup file
[confirm]
[no-cd]
restore backup_file database service="mysql" compose-file="" backup_path="./backups":
    #!/usr/bin/env bash
    set -euo pipefail

    backup_file="{{backup_file}}"
    database="{{database}}"
    service="{{service}}"
    compose_file="{{compose-file}}"
    backup_path="{{backup_path}}"

    echo -e "{{BLUE}}🔄 Restoring MySQL database from backup...{{NORMAL}}"
    echo -e "{{YELLOW}}Backup: $backup_file, Database: $database, Service: $service{{NORMAL}}"

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
        # For gzipped files - pipe from host to container
        if [ -n "$file_arg" ]; then
            gunzip -c "$backup_path/$backup_file" | just container exec-pipe "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} $database" "$file_arg"
        else
            gunzip -c "$backup_path/$backup_file" | just container exec-pipe "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} $database"
        fi
    else
        # For plain SQL files - pipe from host to container
        if [ -n "$file_arg" ]; then
            cat "$backup_path/$backup_file" | just container exec-pipe "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} $database" "$file_arg"
        else
            cat "$backup_path/$backup_file" | just container exec-pipe "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} $database"
        fi
    fi

    echo -e "{{GREEN}}✓ Database '$database' restored successfully from $backup_file{{NORMAL}}"
