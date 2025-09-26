# Just Commons

Universal Just command recipes for container management across projects.

## Overview

This repository contains reusable Just recipes for:
- **Container operations**: start, stop, restart, logs, shell, exec, status
- **Registry authentication**: login, logout, status checks for GitHub Container Registry
- **Image operations**: build, push, pull, tag, test, info, clean
- **Database operations**: PostgreSQL and MySQL database management

## Usage

Add as a Git submodule to your project:

```bash
git submodule add git@github.com:shadoll/just-commons.git
```

Import in your `justfile`:

```bash
# Import universal commands
import 'just-commons/core.just'        # Core utilities
import 'just-commons/container.just'   # Container operations
import 'just-commons/registry.just'    # Registry authentication
import 'just-commons/images.just'      # Image operations

# Import database commands (optional)
import 'just-commons/postgres.just'    # PostgreSQL operations
import 'just-commons/mysql.just'       # MySQL operations
```

## Files

### Core Files
- `core.just` - Core utilities (_detect_runtime, _detect_compose, env-check)
- `container.just` - Universal container operations (start, stop, logs, shell, exec, status)
- `registry.just` - GitHub Container Registry authentication (registry-login, registry-logout, registry-check)
- `images.just` - Universal image operations (image-build, image-push, image-pull, image-tag, etc.)

### Database Files (Optional)
- `postgres.just` - PostgreSQL operations (postgres-sql, postgres-check, postgres-list-databases, etc.)
- `mysql.just` - MySQL operations (mysql-sql, mysql-check, mysql-list-databases, etc.)

### Command Structure
- **Container commands**: No prefix (start, stop, logs, shell, exec, status, restart)
- **All other commands**: Prefixed by file type (image-*, registry-*, postgres-*, mysql-*)

### Usage Examples

```bash
# Container operations (no prefix)
just start postgres
just logs postgres
just shell postgres

# Image operations (image- prefix)
just image-build postgres
just image-push postgres v1.0.0

# Registry operations (registry- prefix)
just registry-login
just registry-check

# Database operations (database- prefix)
just postgres-sql "SELECT version();"
just postgres-check
just mysql-sql "SELECT VERSION();"
```

## Requirements

- Just command runner
- Docker or Podman
- Git
