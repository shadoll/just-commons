# Just Commons - Universal Command Library with Modern Module Architecture
# Version 2.0 - Full Module Migration

# Import core utilities (shared functions)
import 'core.just'

# Declare optional modules - projects can use only what they need
mod? postgres 'postgres'
mod? mysql 'mysql'
mod? volumes 'volumes'
mod? container 'container'
mod? registry 'registry'
mod? images 'images'

# Default recipe - show available modules and commands
[group('help')]
default:
    @echo "{{BOLD}}{{CYAN}}Just Commons - Universal Command Library{{NORMAL}}"
    @echo "{{BLUE}}Version 2.0 - Modern Module Architecture{{NORMAL}}"
    @echo ""
    @echo "{{BOLD}}Available Modules:{{NORMAL}}"
    @echo "  {{YELLOW}}container{{NORMAL}} - Universal container operations (start, stop, logs, shell, exec)"
    @echo "  {{YELLOW}}postgres{{NORMAL}}  - PostgreSQL database operations (sql, check, create-database, etc.)"
    @echo "  {{YELLOW}}mysql{{NORMAL}}     - MySQL database operations (sql, check, create-database, etc.)"
    @echo "  {{YELLOW}}volumes{{NORMAL}}   - Volume management (clean-all, remove, list)"
    @echo "  {{YELLOW}}images{{NORMAL}}    - Image operations (build, push, pull, tag, info, clean)"
    @echo "  {{YELLOW}}registry{{NORMAL}}  - Registry authentication (login, logout, check)"
    @echo ""
    @echo "{{BOLD}}Usage Examples:{{NORMAL}}"
    @echo "  {{GREEN}}just container start postgres{{NORMAL}}     # Start PostgreSQL service"
    @echo "  {{GREEN}}just postgres sql \"SELECT version();\"{{NORMAL}}  # Execute SQL query"
    @echo "  {{GREEN}}just volumes list\"myproject_*\"{{NORMAL}}      # List project volumes"
    @echo "  {{GREEN}}just images build myapp{{NORMAL}}           # Build application image"
    @echo "  {{GREEN}}just registry login{{NORMAL}}               # Login to container registry"
    @echo ""
    @echo "{{BOLD}}Environment Check:{{NORMAL}}"
    @echo "  {{GREEN}}just env-check{{NORMAL}}                    # Verify container runtime availability"
    @echo ""
    @echo "{{BLUE}}For detailed command lists, run:{{NORMAL}} {{CYAN}}just --list{{NORMAL}}"

# Show module-specific help
[group('help')]
help module:
    #!/usr/bin/env bash
    module="{{module}}"

    case "$module" in
        "container")
            echo "{{BOLD}}{{CYAN}}Container Module Commands:{{NORMAL}}"
            echo "  {{YELLOW}}start [service] [compose-file]{{NORMAL}}   - Start services"
            echo "  {{YELLOW}}stop [service] [compose-file]{{NORMAL}}    - Stop services"
            echo "  {{YELLOW}}restart [service] [compose-file]{{NORMAL}} - Restart services"
            echo "  {{YELLOW}}status [service] [compose-file]{{NORMAL}}  - Show service status"
            echo "  {{YELLOW}}logs [service] [compose-file]{{NORMAL}}    - View service logs"
            echo "  {{YELLOW}}shell <service> [compose-file]{{NORMAL}}   - Open shell in container"
            echo "  {{YELLOW}}exec <service> <cmd> [compose-file]{{NORMAL}} - Execute command"
            ;;
        "postgres")
            echo "{{BOLD}}{{CYAN}}PostgreSQL Module Commands:{{NORMAL}}"
            echo "  {{YELLOW}}sql <query> [service] [compose-file]{{NORMAL}}     - Execute SQL query"
            echo "  {{YELLOW}}check [service] [compose-file]{{NORMAL}}           - Check connection"
            echo "  {{YELLOW}}list-databases [service] [compose-file]{{NORMAL}}  - List databases"
            echo "  {{YELLOW}}create-database <name> [service]{{NORMAL}}         - Create database"
            echo "  {{YELLOW}}drop-database <name> [service]{{NORMAL}}           - Drop database (with confirmation)"
            echo "  {{YELLOW}}shell [service] [compose-file]{{NORMAL}}           - Interactive shell"
            echo "  {{YELLOW}}restore <backup> [service] [compose-file]{{NORMAL}} - Restore from backup"
            ;;
        "mysql")
            echo "{{BOLD}}{{CYAN}}MySQL Module Commands:{{NORMAL}}"
            echo "  {{YELLOW}}sql <query> [service] [compose-file]{{NORMAL}}     - Execute SQL query"
            echo "  {{YELLOW}}check [service] [compose-file]{{NORMAL}}           - Check connection"
            echo "  {{YELLOW}}list-databases [service] [compose-file]{{NORMAL}}  - List databases"
            echo "  {{YELLOW}}create-database <name> [service]{{NORMAL}}         - Create database"
            echo "  {{YELLOW}}drop-database <name> [service]{{NORMAL}}           - Drop database (with confirmation)"
            echo "  {{YELLOW}}create-user <user> <pass> [service]{{NORMAL}}      - Create user"
            echo "  {{YELLOW}}grant-privileges <db> <user> [service]{{NORMAL}}   - Grant privileges"
            echo "  {{YELLOW}}shell [service] [compose-file]{{NORMAL}}           - Interactive shell"
            ;;
        "volumes")
            echo "{{BOLD}}{{CYAN}}Volumes Module Commands:{{NORMAL}}"
            echo "  {{YELLOW}}clean-all [compose-file]{{NORMAL}}        - Remove all compose volumes (with confirmation)"
            echo "  {{YELLOW}}remove <volume-name>{{NORMAL}}            - Remove specific volume (with confirmation)"
            echo "  {{YELLOW}}remove-pattern <pattern>{{NORMAL}}        - Remove volumes matching pattern (with confirmation)"
            echo "  {{YELLOW}}list [pattern]{{NORMAL}}                  - List volumes (optionally filtered)"
            ;;
        "images")
            echo "{{BOLD}}{{CYAN}}Images Module Commands:{{NORMAL}}"
            echo "  {{YELLOW}}build <project> [tag]{{NORMAL}}           - Build project image"
            echo "  {{YELLOW}}push <project> [tag]{{NORMAL}}            - Push image to registry"
            echo "  {{YELLOW}}pull <project> [tag]{{NORMAL}}            - Pull image from registry"
            echo "  {{YELLOW}}tag <project> <new-tag>{{NORMAL}}         - Tag existing image"
            echo "  {{YELLOW}}info <project> [tag]{{NORMAL}}            - Show image information"
            echo "  {{YELLOW}}clean <project>{{NORMAL}}                 - Remove project images (with confirmation)"
            echo "  {{YELLOW}}build-all{{NORMAL}}                       - Build all projects with Containerfiles"
            ;;
        "registry")
            echo "{{BOLD}}{{CYAN}}Registry Module Commands:{{NORMAL}}"
            echo "  {{YELLOW}}login{{NORMAL}}                           - Login to container registry"
            echo "  {{YELLOW}}logout{{NORMAL}}                          - Logout from registry"
            echo "  {{YELLOW}}check{{NORMAL}}                           - Check authentication status"
            ;;
        *)
            echo "{{BOLD}}{{RED}}Unknown module: $module{{NORMAL}}"
            echo "{{YELLOW}}Available modules:{{NORMAL}} container, postgres, mysql, volumes, images, registry"
            ;;
    esac