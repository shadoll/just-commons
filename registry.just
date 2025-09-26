# Registry operations

# Login to container registry
[group('registry')]
registry-login:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    NC='\033[0m'

    # Load environment variables from .env file
    if [ -f ".env" ]; then
        source .env
    else
        echo -e "${RED}Error: .env file not found${NC}" >&2
        echo "Create .env file with:" >&2
        echo "GITHUB_USERNAME=your-username" >&2
        echo "GITHUB_TOKEN=your-token" >&2
        echo "Or copy from .env.example and modify" >&2
        exit 1
    fi

    # Check loaded variables
    if [ -z "${GITHUB_USERNAME:-}" ]; then
        echo -e "${RED}Error: GITHUB_USERNAME not set in .env file${NC}" >&2
        exit 1
    fi

    if [ -z "${GITHUB_TOKEN:-}" ]; then
        echo -e "${RED}Error: GITHUB_TOKEN not set in .env file${NC}" >&2
        echo "Add your token to .env file: GITHUB_TOKEN=your-token" >&2
        exit 1
    fi

    # Detect runtime
    runtime=$(just _detect_runtime)

    echo -e "${BLUE}Logging in to {{REGISTRY}} as $GITHUB_USERNAME...${NC}"

    if echo "$GITHUB_TOKEN" | $runtime login {{REGISTRY}} -u "$GITHUB_USERNAME" --password-stdin; then
        echo -e "${GREEN}✓ Successfully logged in to {{REGISTRY}}${NC}"
    else
        echo -e "${RED}✗ Failed to login to {{REGISTRY}}${NC}" >&2
        exit 1
    fi

# Logout from container registry
[group('registry')]
registry-logout:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m'

    runtime=$(just _detect_runtime)

    echo -e "${BLUE}Logging out from {{REGISTRY}}...${NC}"

    $runtime logout {{REGISTRY}}

    echo -e "${GREEN}✓ Successfully logged out from {{REGISTRY}}${NC}"


# Check authentication and registry status
[group('registry')]
registry-check:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'

    echo -e "${BLUE}=== Authentication Status ===${NC}"
    echo ""

    # Check .env file and variables
    echo -e "${BLUE}1. Environment Configuration (.env file):${NC}"

    if [ ! -f ".env" ]; then
        echo -e "${RED}  ✗ .env file not found${NC}"
        echo "    Edit .env file manually or copy from .env.example"
        exit 1
    fi

    source .env

    if [ -n "${GITHUB_USERNAME:-}" ]; then
        echo -e "${GREEN}  ✓ GITHUB_USERNAME: $GITHUB_USERNAME${NC}"
    else
        echo -e "${RED}  ✗ GITHUB_USERNAME: not set in .env${NC}"
        echo "    Add GITHUB_USERNAME=your-username to .env file"
        exit 1
    fi

    if [ -n "${GITHUB_TOKEN:-}" ]; then
        # Show masked token
        token_len=${#GITHUB_TOKEN}
        if [ $token_len -gt 8 ]; then
            prefix=${GITHUB_TOKEN:0:4}
            suffix=${GITHUB_TOKEN: -4}
            masked_middle=$(printf "%*s" $((token_len-8)) | tr ' ' '*')
            echo -e "${GREEN}  ✓ GITHUB_TOKEN: ${prefix}${masked_middle}${suffix} (${token_len} chars)${NC}"
        else
            echo -e "${GREEN}  ✓ GITHUB_TOKEN: $(printf "%*s" $token_len | tr ' ' '*') (${token_len} chars)${NC}"
        fi
    else
        echo -e "${RED}  ✗ GITHUB_TOKEN: not set in .env${NC}"
        echo "    Add GITHUB_TOKEN=your-token to .env file"
        exit 1
    fi
    echo ""

    # Check token validity
    echo -e "${BLUE}2. GitHub API Authentication:${NC}"
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user)

    if echo "$response" | grep -q '"login"'; then
        username=$(echo "$response" | grep '"login"' | sed 's/.*"login": "\([^"]*\)".*/\1/')
        echo -e "${GREEN}  ✓ Token is valid - authenticated as: $username${NC}"

        # Check token scopes
        scopes_response=$(curl -s -I -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user)
        if echo "$scopes_response" | grep -i "x-oauth-scopes" > /dev/null; then
            scopes=$(echo "$scopes_response" | grep -i "x-oauth-scopes" | cut -d: -f2- | tr -d '\r')

            # Check for required scopes
            if echo "$scopes" | grep -q "write:packages"; then
                echo -e "${GREEN}  ✓ Has write:packages scope (push enabled)${NC}"
            else
                echo -e "${YELLOW}  ⚠ Missing write:packages scope (push disabled)${NC}"
            fi

            if echo "$scopes" | grep -q "read:packages"; then
                echo -e "${GREEN}  ✓ Has read:packages scope (pull enabled)${NC}"
            else
                echo -e "${YELLOW}  ⚠ Missing read:packages scope (pull may fail)${NC}"
            fi
        fi
    else
        echo -e "${RED}  ✗ Token is invalid or expired${NC}"
        if echo "$response" | grep -q "Bad credentials"; then
            echo "    The token appears to be malformed or expired"
        elif echo "$response" | grep -q "rate limit"; then
            echo "    Rate limited - try again later"
        fi
        exit 1
    fi
    echo ""

    # Check registry login
    echo -e "${BLUE}3. Container Registry Test:${NC}"
    runtime=$(just _detect_runtime)

    if echo "$GITHUB_TOKEN" | $runtime login {{REGISTRY}} -u "$GITHUB_USERNAME" --password-stdin >/dev/null 2>&1; then
        echo -e "${GREEN}  ✓ Registry login successful${NC}"
    else
        echo -e "${RED}  ✗ Registry login failed${NC}"
        echo "    Check your token permissions"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}✓ All authentication checks passed!${NC}"
    echo -e "${BLUE}You can now use: just push <project>, just pull <project>${NC}"