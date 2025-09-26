# Universal MySQL database operations

# Execute MySQL SQL query
mysql-sql query service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    query="{{query}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$query" ]; then
        echo "Error: SQL query is required" >&2
        echo "Usage: just mysql-sql \"SELECT VERSION();\"" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Executing MySQL query in service: $service{{NC}}"
    echo -e "{{YELLOW}}Query: $query{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"$query\"" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"$query\""
    fi

# Check MySQL connection and status
mysql-check service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Checking MySQL status in service: $service{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysqladmin -u root -p\${MYSQL_ROOT_PASSWORD} ping" "$file_arg"
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SELECT VERSION();'" "$file_arg"
    else
        just exec "$service" "mysqladmin -u root -p\${MYSQL_ROOT_PASSWORD} ping"
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SELECT VERSION();'"
    fi

# List MySQL databases
mysql-list-databases service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Listing MySQL databases in service: $service{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SHOW DATABASES;'" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SHOW DATABASES;'"
    fi

# List MySQL users
mysql-list-users service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Listing MySQL users in service: $service{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SELECT User, Host FROM mysql.user;'" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SELECT User, Host FROM mysql.user;'"
    fi

# Create MySQL database
mysql-create-database database service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    database="{{database}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$database" ]; then
        echo "Error: Database name is required" >&2
        echo "Usage: just mysql-create-database mydb" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Creating MySQL database: $database{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'CREATE DATABASE \`$database\`;'" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'CREATE DATABASE \`$database\`;'"
    fi

# Drop MySQL database
mysql-drop-database database service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    database="{{database}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$database" ]; then
        echo "Error: Database name is required" >&2
        echo "Usage: just mysql-drop-database mydb" >&2
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
        echo -e "{{BLUE}}Dropping MySQL database: $database{{NC}}"

        if [ -n "$file_arg" ]; then
            just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'DROP DATABASE \`$database\`;'" "$file_arg"
        else
            just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'DROP DATABASE \`$database\`;'"
        fi
    else
        echo "Operation cancelled"
    fi

# Create MySQL user
mysql-create-user username password service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    username="{{username}}"
    password="{{password}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$username" ] || [ -z "$password" ]; then
        echo "Error: Username and password are required" >&2
        echo "Usage: just mysql-create-user myuser mypassword" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Creating MySQL user: $username{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"CREATE USER '$username'@'%' IDENTIFIED BY '$password';\"" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"CREATE USER '$username'@'%' IDENTIFIED BY '$password';\""
    fi

# Grant MySQL privileges
mysql-grant-privileges database username service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    database="{{database}}"
    username="{{username}}"
    service="{{service}}"
    compose_file="{{compose-file}}"

    if [ -z "$database" ] || [ -z "$username" ]; then
        echo "Error: Database and username are required" >&2
        echo "Usage: just mysql-grant-privileges mydb myuser" >&2
        exit 1
    fi

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Granting privileges on $database to $username{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"GRANT ALL PRIVILEGES ON \\\`$database\\\`.* TO '$username'@'%'; FLUSH PRIVILEGES;\"" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e \"GRANT ALL PRIVILEGES ON \\\`$database\\\`.* TO '$username'@'%'; FLUSH PRIVILEGES;\""
    fi

# MySQL interactive shell
mysql-shell service="mysql" compose-file="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"

    # Build compose file argument
    file_arg=""
    if [ -n "$compose_file" ]; then
        file_arg="$compose_file"
    fi

    echo -e "{{BLUE}}Opening MySQL interactive shell in service: $service{{NC}}"

    if [ -n "$file_arg" ]; then
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD}" "$file_arg"
    else
        just exec "$service" "mysql -u root -p\${MYSQL_ROOT_PASSWORD}"
    fi