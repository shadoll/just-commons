# Just Commons

Universal Just command recipes for container management across projects.

## Overview

This repository contains reusable Just recipes for:
- **Container operations**: start, stop, restart, logs, shell, exec, status
- **Registry authentication**: login, logout, status checks for GitHub Container Registry
- **Image operations**: build, push, pull, tag, test, info, clean

## Usage

Add as a Git submodule to your project:

```bash
git submodule add git@github.com:shadoll/just-commons.git
```

Import in your `justfile`:

```bash
# Import universal commands
import 'just-commons/container.just'
import 'just-commons/registry.just'
import 'just-commons/images.just'

# Your project-specific commands
import 'just/postgres.just'
import 'just/servapp.just'
```

## Files

- `container.just` - Universal container operations (start, stop, logs, shell, exec, status)
- `registry.just` - GitHub Container Registry authentication
- `images.just` - Universal image build/push/pull operations

## Requirements

- Just command runner
- Docker or Podman
- Git

## Projects Using This

- [servass](https://github.com/shadoll/servass) - Universal container image management
- [servass_sh](https://github.com/shadoll/servass_sh) - Production deployment (SH)
- [servass_ri](https://github.com/shadoll/servass_ri) - Production deployment (RI)