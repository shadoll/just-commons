# Universal image operations - works for any project

# Detect container runtime
_detect_runtime:
    #!/usr/bin/env bash
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        echo "docker"
    elif command -v podman >/dev/null 2>&1; then
        echo "podman"
    else
        echo "Error: No container runtime available (docker or podman)" >&2
        exit 1
    fi

# Build any project's container image
build project *args="":
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'

    project="{{project}}"
    args="{{args}}"

    # Use default tag if not specified
    tag="commit-$(git rev-parse --short HEAD)"

    # Validate project directory exists
    if [ ! -d "$project" ]; then
        echo -e "${RED}Error: Project directory '$project' not found${NC}" >&2
        exit 1
    fi

    # Look for Containerfile or Dockerfile
    containerfile=""
    if [ -f "$project/Containerfile" ]; then
        containerfile="Containerfile"
    elif [ -f "$project/Dockerfile" ]; then
        containerfile="Dockerfile"
    else
        echo -e "${RED}Error: No Containerfile or Dockerfile found in '$project'${NC}" >&2
        exit 1
    fi

    # Detect runtime
    runtime=$(just _detect_runtime)

    # Build image
    echo -e "${BLUE}Building $project image with tag: $tag${NC}"
    cd "$project"

    # Create full image name with registry
    full_image_name="{{REGISTRY}}/${GITHUB_USERNAME:-local}/$project:$tag"

    echo -e "${YELLOW}Building: $full_image_name${NC}"
    $runtime build $args -t "$full_image_name" -f "$containerfile" .

    # Also tag as local for development
    $runtime tag "$full_image_name" "$project:$tag"
    $runtime tag "$full_image_name" "$project:latest"

    echo -e "${GREEN}✓ Image $project:$tag built successfully${NC}"
    echo -e "${GREEN}✓ Tagged as: $full_image_name${NC}"
    echo -e "${GREEN}✓ Local tags: $project:$tag, $project:latest${NC}"

# Push any project's image to registry
push project tag=DEFAULT_TAG:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    NC='\033[0m'

    project="{{project}}"
    tag="{{tag}}"

    # Load environment variables from .env file
    if [ -f ".env" ]; then
        source .env
    else
        echo -e "${RED}Error: .env file not found${NC}" >&2
        echo "Create .env file with your GitHub credentials" >&2
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

    # Login first
    echo "$GITHUB_TOKEN" | $runtime login {{REGISTRY}} -u "$GITHUB_USERNAME" --password-stdin

    # Handle special case: pushing as "latest" means push both commit tag and latest
    if [ "$tag" = "latest" ]; then
        # Get current commit tag
        if git rev-parse --git-dir >/dev/null 2>&1; then
            commit_tag="commit-$(git rev-parse --short HEAD)"
        else
            commit_tag="build-$(date '+%Y%m%d-%H%M%S')"
        fi

        commit_image_name="{{REGISTRY}}/$GITHUB_USERNAME/$project:$commit_tag"
        latest_image_name="{{REGISTRY}}/$GITHUB_USERNAME/$project:latest"

        echo -e "${BLUE}Pushing $project as latest (both $commit_tag and latest tags)...${NC}"

        # Tag the local image with both commit and latest registry tags
        $runtime tag "$project:latest" "$commit_image_name"
        $runtime tag "$project:latest" "$latest_image_name"

        # Push both tags
        $runtime push "$commit_image_name"
        $runtime push "$latest_image_name"

        echo -e "${GREEN}✓ Pushed as: $commit_image_name${NC}"
        echo -e "${GREEN}✓ Pushed as: $latest_image_name${NC}"
    else
        # Normal push: just push the specific tag
        full_image_name="{{REGISTRY}}/$GITHUB_USERNAME/$project:$tag"

        echo -e "${BLUE}Pushing $project:$tag to registry...${NC}"
        $runtime push "$full_image_name"
        echo -e "${GREEN}✓ Image pushed successfully: $full_image_name${NC}"
    fi

# Pull any project's image from registry
pull project tag=DEFAULT_TAG:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    NC='\033[0m'

    project="{{project}}"
    tag="{{tag}}"

    # Load environment variables from .env file
    if [ -f ".env" ]; then
        source .env
    else
        echo -e "${RED}Error: .env file not found${NC}" >&2
        echo "Create .env file with your GitHub credentials" >&2
        exit 1
    fi

    # Check loaded variables
    if [ -z "${GITHUB_USERNAME:-}" ]; then
        echo -e "${RED}Error: GITHUB_USERNAME not set in .env file${NC}" >&2
        exit 1
    fi

    # Detect runtime
    runtime=$(just _detect_runtime)

    # Create full image name
    full_image_name="{{REGISTRY}}/$GITHUB_USERNAME/$project:$tag"

    echo -e "${BLUE}Pulling $project:$tag from registry...${NC}"

    $runtime pull "$full_image_name"

    # Tag locally for convenience
    $runtime tag "$full_image_name" "$project:$tag"

    echo -e "${GREEN}✓ Image pulled successfully: $full_image_name${NC}"
    echo -e "${GREEN}✓ Tagged locally as: $project:$tag${NC}"

# Tag any project's existing image
tag project new_tag:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    RED='\033[0;31m'
    NC='\033[0m'

    project="{{project}}"
    new_tag="{{new_tag}}"

    # Detect runtime
    runtime=$(just _detect_runtime)

    echo -e "${BLUE}Tagging $project:latest as $project:$new_tag${NC}"

    $runtime tag "$project:latest" "$project:$new_tag"

    # Also create registry tag if username is set
    if [ -n "${GITHUB_USERNAME:-}" ]; then
        registry_tag="{{REGISTRY}}/$GITHUB_USERNAME/$project:$new_tag"
        $runtime tag "$project:latest" "$registry_tag"
        echo -e "${GREEN}✓ Tagged as: $project:$new_tag and $registry_tag${NC}"
    else
        echo -e "${GREEN}✓ Tagged as: $project:$new_tag${NC}"
    fi

# Test any project's image
test project tag="latest":
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'

    project="{{project}}"
    tag="{{tag}}"
    runtime=$(just _detect_runtime)

    echo -e "${BLUE}Testing $project image: $project:$tag${NC}"

    # Check if image exists
    if ! $runtime images "$project:$tag" | grep -q "$project"; then
        echo -e "${RED}Error: Image $project:$tag not found${NC}" >&2
        echo "Build it first with: just build $project $tag" >&2
        exit 1
    fi

    echo -e "${YELLOW}Starting temporary $project container for testing...${NC}"

    # Run temporary container
    container_id=$($runtime run -d --rm "$project:$tag" sleep 30)

    echo "Container ID: $container_id"

    # Wait for container to start
    sleep 5

    # Basic test - check if container is running
    if $runtime exec "$container_id" echo "Container is responsive" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Container is responsive${NC}"
    else
        echo -e "${RED}✗ Container test failed${NC}"
    fi

    # Cleanup
    echo -e "${YELLOW}Cleaning up test container...${NC}"
    $runtime stop "$container_id" >/dev/null 2>&1

    echo -e "${GREEN}✓ $project image test completed${NC}"

# Show any project's image information
info project tag="latest":
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    BLUE='\033[0;34m'
    GREEN='\033[0;32m'
    NC='\033[0m'

    project="{{project}}"
    tag="{{tag}}"
    runtime=$(just _detect_runtime)

    echo -e "${BLUE}$project Image Information: $project:$tag${NC}"
    echo ""

    if $runtime images "$project:$tag" | grep -q "$project"; then
        echo -e "${GREEN}Image Details:${NC}"
        $runtime images "$project:$tag"
        echo ""

        echo -e "${GREEN}Image History (last 10 layers):${NC}"
        $runtime history "$project:$tag" | head -10
    else
        echo "Image $project:$tag not found locally"
        echo "Build it with: just build $project $tag"
    fi

# List all project images
list:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    BLUE='\033[0;34m'
    NC='\033[0m'

    runtime=$(just _detect_runtime)

    echo -e "${BLUE}Local Project Images:${NC}"

    # List images for known projects
    for project in postgres servapp; do
        if [ -d "$project" ]; then
            echo -e "\n${BLUE}$project images:${NC}"
            $runtime images "$project" 2>/dev/null || echo "  No images found"
        fi
    done

    # List any other images that might be project images
    echo -e "\n${BLUE}Registry images:${NC}"
    if [ -n "${GITHUB_USERNAME:-}" ]; then
        $runtime images | grep "{{REGISTRY}}/$GITHUB_USERNAME" || echo "  No registry images found"
    else
        echo "  Set GITHUB_USERNAME to see registry images"
    fi

# Remove any project's local images
clean project:
    #!/usr/bin/env bash
    set -euo pipefail

    # Colors
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    NC='\033[0m'

    project="{{project}}"

    runtime=$(just _detect_runtime)

    echo -e "${YELLOW}Removing all local images for: $project${NC}"

    # Remove local tags (disable pipefail temporarily for this section)
    set +e

    # Remove common local project tags
    for tag in latest commit-* build-*; do
        $runtime rmi "$project:$tag" 2>/dev/null || true
        $runtime rmi "localhost/$project:$tag" 2>/dev/null || true
        $runtime rmi "localhost/${project}_${project}:$tag" 2>/dev/null || true
    done

    # Remove all images matching project name patterns
    $runtime images --format "\{\{.Repository\}\}:\{\{.Tag\}\}" | grep -E "^($project|localhost/$project|localhost/${project}_${project})" | while read -r img; do
        [ -n "$img" ] && $runtime rmi "$img" 2>/dev/null || true
    done

    # Remove registry tags if they exist
    if [ -n "${GITHUB_USERNAME:-}" ]; then
        $runtime images --format "\{\{.Repository\}\}:\{\{.Tag\}\}" | grep "{{REGISTRY}}/$GITHUB_USERNAME/$project" | while read -r img; do
            [ -n "$img" ] && $runtime rmi "$img" 2>/dev/null || true
        done
    fi

    # Re-enable strict error handling
    set -e

    echo -e "${GREEN}✓ Cleaned local images for: $project${NC}"

# Quick build all known projects
build-all:
    @echo "{{BLUE}}Building all known projects...{{NC}}"
    @just build postgres
    @just build servapp
    @echo "{{GREEN}}✓ All projects built successfully{{NC}}"

# Quick push all known projects
push-all tag=DEFAULT_TAG:
    @echo "{{BLUE}}Pushing all known projects with tag: {{tag}}{{NC}}"
    @just push postgres {{tag}}
    @just push servapp {{tag}}
    @echo "{{GREEN}}✓ All projects pushed successfully{{NC}}"