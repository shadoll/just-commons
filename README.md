# Just Commons - Universal Command Library

**Version 2.0 - Modern Module Architecture**

A collection of universal Just command modules for container management, database operations, and development workflows. Built with Just's modern module system and designed for maximum reusability.

## 🚀 Features

- **🎯 Module-Based Architecture**: Clean separation using Just's native module system
- **🎨 Modern Just Features**: Built-in colors, groups, and confirm attributes
- **📦 Optional Modules**: Include only what you need
- **🐳 Universal Container Support**: Works with Docker and Podman
- **🗄️ Database Operations**: PostgreSQL and MySQL support
- **🔒 Built-in Safety**: Confirmation prompts for destructive operations
- **🏗️ Zero Dependencies**: Pure Just recipes with automatic runtime detection

## 📋 Requirements

### Just Command Runner

This library requires **Just 1.31.0 or later** for module support and modern features.

#### Installation on Ubuntu 24.04 LTS

**Method 1: Snap (Recommended for latest version)**
```bash
sudo snap install just --classic
```

**Method 2: Manual Installation from GitHub**
```bash
# Get the latest version
JUST_VERSION=$(curl -s "https://api.github.com/repos/casey/just/releases/latest" | grep -Po '"tag_name": "\K[0-9.]+')

# Download and install
wget -qO just.tar.gz "https://github.com/casey/just/releases/latest/download/just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz"
tar -xzf just.tar.gz
sudo mv just /usr/local/bin/
chmod +x /usr/local/bin/just

# Verify installation
just --version
```

#### Other Platforms
- **macOS**: `brew install just`
- **Windows**: `choco install just` or `scoop install just`
- **Other Linux**: See [official installation guide](https://github.com/casey/just#installation)

### Other Requirements
- Docker or Podman
- Git

## 🏗️ Module Architecture

```
just-commons/
├── README.md              # This documentation
├── justfile               # Main file with module declarations and help
├── core.just              # Shared utilities (imported)
├── postgres/
│   └── mod.just          # PostgreSQL module
├── mysql/
│   └── mod.just          # MySQL module
├── volumes/
│   └── mod.just          # Volume management module
├── container/
│   └── mod.just          # Container operations module
├── registry/
│   └── mod.just          # Registry authentication module
└── images/
    └── mod.just          # Image operations module
```

## 🔧 Usage

### Add as Git Submodule

```bash
git submodule add git@github.com:shadoll/just-commons.git just-commons
cd just-commons
git checkout main
```

### Import in Your Justfile

```just
# Import core utilities (required)
import 'just-commons/core.just'

# Declare optional modules (use only what you need)
mod? postgres 'just-commons/postgres'
mod? mysql 'just-commons/mysql'
mod? volumes 'just-commons/volumes'
mod? container 'just-commons/container'
mod? registry 'just-commons/registry'
mod? images 'just-commons/images'
```

### Example Project Justfile

```just
# My Project Justfile
import 'just-commons/core.just'

# Only include modules I need
mod? container 'just-commons/container'
mod? postgres 'just-commons/postgres'
mod? volumes 'just-commons/volumes'

# Project-specific commands
[group('project')]
setup:
    just container start
    just postgres sql "CREATE DATABASE myapp;"

[group('project')]
teardown:
    just volumes clean-all
```

## 📚 Available Modules

### 🐳 Container Module (`container`)

**Universal container operations with optional compose file support**

```bash
just container start [service] [compose-file]     # Start services
just container stop [service] [compose-file]      # Stop services
just container restart [service] [compose-file]   # Restart services
just container status [service] [compose-file]    # Show service status
just container logs [service] [compose-file]      # View service logs
just container shell <service> [compose-file]     # Open shell in container
just container exec <service> <cmd> [compose-file] # Execute command
```

### 🗄️ Database Modules

#### PostgreSQL Module (`postgres`)

```bash
just postgres sql <query> [service] [compose-file]        # Execute SQL query
just postgres check [service] [compose-file]              # Check connection
just postgres list-databases [service] [compose-file]     # List databases
just postgres list-users [service] [compose-file]         # List users
just postgres create-database <name> [service]            # Create database
just postgres drop-database <name> [service]              # Drop database (with confirmation)
just postgres shell [service] [compose-file]              # Interactive shell
just postgres restore <backup> [service] [compose-file]   # Restore from backup (with confirmation)
```

#### MySQL Module (`mysql`)

```bash
just mysql sql <query> [service] [compose-file]           # Execute SQL query
just mysql check [service] [compose-file]                 # Check connection
just mysql list-databases [service] [compose-file]        # List databases
just mysql list-users [service] [compose-file]            # List users
just mysql create-database <name> [service]               # Create database
just mysql drop-database <name> [service]                 # Drop database (with confirmation)
just mysql create-user <username> <password> [service]    # Create user
just mysql grant-privileges <database> <username> [service] # Grant privileges
just mysql shell [service] [compose-file]                 # Interactive shell
just mysql restore <backup> <database> [service]          # Restore from backup (with confirmation)
```

### 💾 Volume Module (`volumes`)

**Safe volume management with built-in confirmations**

```bash
just volumes clean-all [compose-file]                     # Remove all compose volumes (with confirmation)
just volumes remove <volume-name>                         # Remove specific volume (with confirmation)
just volumes remove-pattern <pattern>                     # Remove volumes matching pattern (with confirmation)
just volumes list [pattern]                               # List volumes (optionally filtered)
```

### 🐋 Images Module (`images`)

**Universal image operations with automatic registry detection**

```bash
just images build <project> [tag]                         # Build project image
just images push <project> [tag]                          # Push image to registry
just images pull <project> [tag]                          # Pull image from registry
just images tag <project> <new-tag>                       # Tag existing image
just images info <project> [tag]                          # Show image information
just images clean <project>                               # Remove project images (with confirmation)
just images build-all                                     # Build all projects with Containerfiles
```

### 🔐 Registry Module (`registry`)

**Container registry authentication management**

```bash
just registry login                                       # Login to container registry
just registry logout                                      # Logout from registry
just registry check                                       # Check authentication status
```

### 🔧 Core Utilities

**Shared functions and environment checking**

```bash
just env-check                                           # Check container runtime availability
just _detect_runtime                                     # Internal: Detect Docker/Podman
just _detect_compose                                     # Internal: Detect compose command
```

## 🎨 Modern Just Features

### Built-in Colors
Uses Just's native color constants instead of custom ANSI codes:
- `{{RED}}`, `{{GREEN}}`, `{{BLUE}}`, `{{YELLOW}}`
- `{{BOLD}}`, `{{NORMAL}}`

### Command Groups
All commands are organized with `[group('name')]` attributes:
- `container` - Container operations
- `database` - Database operations
- `volumes` - Volume management
- `images` - Image operations
- `registry` - Registry operations
- `environment` - Environment checking

### Safety Confirmations
Destructive operations use `[confirm]` attribute:
- Volume removal operations
- Database dropping
- Image cleaning
- Backup restoration

## 🌍 Environment Configuration

### Required for Registry Operations
```bash
# .env file
GITHUB_USERNAME=your-username
GITHUB_TOKEN=ghp_your-token
REGISTRY=ghcr.io
```

### Optional Overrides
```bash
# Auto-detected, but can be explicitly set
CONTAINER_RUNTIME=docker  # or 'podman'
COMPOSE_CMD="docker compose"  # or 'podman-compose'
```

## 📖 Usage Examples

### Development Workflow
```bash
# Environment setup
just env-check                           # Verify container runtime
just registry login                      # Authenticate with registry

# Container management
just container start postgres            # Start PostgreSQL service
just container logs postgres             # View logs
just postgres check                      # Test database connection

# Development operations
just postgres sql "CREATE DATABASE myapp;" # Create development database
just images build myapp                  # Build application image
just images push myapp dev               # Push development version
```

### Production Deployment
```bash
# Pull latest images
just images pull myapp latest
just images pull postgres 15

# Database operations
just postgres restore latest-backup.sql  # Restore from backup (with confirmation)
just postgres sql "ANALYZE;"             # Optimize database

# Volume management
just volumes list "production_*"         # List production volumes
just volumes clean-all compose.prod.yml  # Clean up old volumes (with confirmation)
```

### Multi-Database Setup
```bash
# PostgreSQL setup
just postgres create-database main_db
just postgres sql "CREATE USER app_user WITH PASSWORD 'secret';" postgres

# MySQL setup
just mysql create-database cache_db
just mysql create-user cache_user secret123 mysql
just mysql grant-privileges cache_db cache_user mysql
```

## 🆕 Migration from Version 1.x

**Breaking Changes in Version 2.0:**

### Command Structure
- **Old**: `just postgres-sql "query"`
- **New**: `just postgres sql "query"`

### Module Declaration
- **Old**: `import 'just-commons/postgres.just'`
- **New**: `mod postgres 'just-commons/postgres'`

### Color Variables
- **Old**: Custom `${GREEN}`, `${RED}` variables
- **New**: Built-in `{{GREEN}}`, `{{RED}}` constants

### Migration Steps
1. Update to Just 1.31.0+
2. Replace `import` statements with `mod` declarations
3. Update command calls to use module syntax
4. Remove custom color variable definitions

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-module`
3. Follow existing module patterns
4. Use modern Just features (groups, confirm, built-in colors)
5. Test across different environments
6. Update documentation
7. Submit pull request

## 📝 License

MIT License - see LICENSE file for details.

## 🔗 Links

- [Just Command Runner](https://just.systems/)
- [Just Documentation](https://just.systems/man/en/)
- [Docker](https://docs.docker.com/)
- [Podman](https://podman.io/)

---

**Just Commons v2.0** - Modern, modular, and maintainable command automation for container-based projects.