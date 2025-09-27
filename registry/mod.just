# Container registry authentication and management

# Login to container registry
login:
    #!/usr/bin/env bash
    set -euo pipefail

    if [ -z "${GITHUB_USERNAME:-}" ] || [ -z "${GITHUB_TOKEN:-}" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} GITHUB_USERNAME and GITHUB_TOKEN environment variables must be set" >&2
        echo "{{YELLOW}}Please set these in your .env file or environment{{NORMAL}}" >&2
        exit 1
    fi

    runtime=$(just _detect_runtime)
    registry="${REGISTRY:-ghcr.io}"

    echo -e "{{BLUE}}Logging into registry: $registry{{NORMAL}}"
    echo "$GITHUB_TOKEN" | $runtime login "$registry" -u "$GITHUB_USERNAME" --password-stdin

    echo -e "{{GREEN}}✓ Successfully logged into $registry{{NORMAL}}"

# Logout from container registry
logout:
    #!/usr/bin/env bash
    set -euo pipefail

    runtime=$(just _detect_runtime)
    registry="${REGISTRY:-ghcr.io}"

    echo -e "{{BLUE}}Logging out from registry: $registry{{NORMAL}}"
    $runtime logout "$registry"

    echo -e "{{GREEN}}✓ Successfully logged out from $registry{{NORMAL}}"

# Check registry authentication status
check:
    #!/usr/bin/env bash
    set -euo pipefail

    runtime=$(just _detect_runtime)
    registry="${REGISTRY:-ghcr.io}"

    echo -e "{{BLUE}}Registry Configuration:{{NORMAL}}"
    echo -e "{{YELLOW}}Registry:{{NORMAL}} $registry"
    echo -e "{{YELLOW}}Username:{{NORMAL}} ${GITHUB_USERNAME:-'Not set'}"
    echo -e "{{YELLOW}}Token:{{NORMAL}} ${GITHUB_TOKEN:+'Set'}${GITHUB_TOKEN:-'Not set'}"
    echo ""

    echo -e "{{BLUE}}Testing registry authentication...{{NORMAL}}"

    # Check if we can access the registry
    if echo "$GITHUB_TOKEN" | $runtime login "$registry" -u "$GITHUB_USERNAME" --password-stdin >/dev/null 2>&1; then
        echo -e "{{GREEN}}✓ Registry authentication successful{{NORMAL}}"

        # Show configured registries
        echo -e "{{BLUE}}Configured registries:{{NORMAL}}"
        $runtime system info --format "{{{{.RegistryConfig.IndexConfigs}}}}" 2>/dev/null || echo "Registry config not available"
    else
        echo -e "{{RED}}✗ Registry authentication failed{{NORMAL}}"
        echo -e "{{YELLOW}}Please check your GITHUB_USERNAME and GITHUB_TOKEN{{NORMAL}}"
        exit 1
    fi