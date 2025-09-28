# Container images module - comprehensive image management
# Supports multi-architecture builds, flexible naming, and registry operations

# Build project image with multi-architecture support
[no-cd]
build project="" tag="" local="false":
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"
    tag="{{tag}}"
    local="{{local}}"

    # Determine discovery directory and project
    if [ -z "$project" ]; then
        discovery_dir="."
        echo -e "{{BLUE}}🔍 Auto-discovering project...{{NORMAL}}"
        project=$(just _get_project_name)
        echo -e "{{GREEN}}✓ Using project: $project{{NORMAL}}"
    else
        # Check if project directory exists
        if [ ! -d "$project" ]; then
            echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Project directory '$project' not found" >&2
            exit 1
        fi
        discovery_dir="$project"
        echo -e "{{BLUE}}🔍 Building project: $project{{NORMAL}}"
    fi

    # Use unified discovery logic
    discovery_result=$(just _discover_containerfile_in "$discovery_dir")
    read -r containerfile discovered_project build_context <<< "$discovery_result"

    echo -e "{{GREEN}}✓ Found $containerfile{{NORMAL}}"

    # Generate tag if not provided
    if [ -z "$tag" ]; then
        tag=$(just _generate_default_tag)
    fi

    # Get image name using new naming logic
    image_name=$(just _get_image_name "$tag")

    # Detect platforms
    platforms=$(just _detect_platforms "$containerfile")

    echo -e "{{BLUE}}Building image: $image_name{{NORMAL}}"
    echo -e "{{YELLOW}}Using: $containerfile{{NORMAL}}"
    echo -e "{{YELLOW}}Build context: $build_context{{NORMAL}}"
    echo -e "{{YELLOW}}Platforms: $platforms{{NORMAL}}"

    runtime=$(just _detect_runtime)

    # Check if multi-platform build is needed
    if [[ "$platforms" == *","* ]] && [ "$local" != "true" ]; then
        echo -e "{{BLUE}}Multi-platform build detected: $platforms{{NORMAL}}"

        # Use buildx for multi-platform
        if ! $runtime buildx version >/dev/null 2>&1; then
            echo "{{BOLD}}{{RED}}Error:{{NORMAL}} buildx required for multi-platform builds" >&2
            echo "{{YELLOW}}Run: $runtime buildx create --use{{NORMAL}}" >&2
            exit 1
        fi

        # Ensure buildx builder exists and is active
        if ! $runtime buildx inspect >/dev/null 2>&1; then
            echo -e "{{BLUE}}Setting up buildx builder...{{NORMAL}}"
            $runtime buildx create --use --name just-commons-builder >/dev/null 2>&1 || true
        fi

        echo -e "{{YELLOW}}Multi-platform builds cannot be loaded locally - will build and push to registry{{NORMAL}}"
        echo -e "{{BLUE}}Building multi-platform image: $platforms{{NORMAL}}"

        # For podman, build for each platform and create manifest
        IFS=',' read -ra PLATFORM_ARRAY <<< "$platforms"

        # Build for each platform
        for platform in "${PLATFORM_ARRAY[@]}"; do
            echo -e "{{BLUE}}Building for platform: $platform{{NORMAL}}"
            platform_tag="${image_name}-${platform//\//-}"

            $runtime buildx build \
                --platform "$platform" \
                -f "$containerfile" \
                -t "$platform_tag" \
                --load \
                "$build_context"

            # Push platform-specific image
            $runtime push "$platform_tag"
        done

        # Create and push manifest
        echo -e "{{BLUE}}Creating multi-platform manifest{{NORMAL}}"

        # Remove existing manifest if it exists
        $runtime manifest rm "$image_name" 2>/dev/null || true

        manifest_cmd="$runtime manifest create $image_name"
        for platform in "${PLATFORM_ARRAY[@]}"; do
            platform_tag="${image_name}-${platform//\//-}"
            manifest_cmd="$manifest_cmd $platform_tag"
        done
        eval "$manifest_cmd"

        echo -e "{{BLUE}}Pushing multi-platform manifest to registry{{NORMAL}}"
        $runtime manifest push "$image_name"
    else
        if [[ "$platforms" == *","* ]]; then
            # Local build requested for multi-platform - use local platform only
            local_platform="linux/$(uname -m)"
            if [ "$(uname -m)" = "x86_64" ]; then
                local_platform="linux/amd64"
            elif [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then
                local_platform="linux/arm64"
            fi
            echo -e "{{BLUE}}Local-only build (from multi-platform): $local_platform{{NORMAL}}"
            platforms="$local_platform"
        else
            echo -e "{{BLUE}}Single platform build: $platforms{{NORMAL}}"
        fi

        # Handle single platform builds with potential platform specification
        if grep -q "FROM.*--platform" "$containerfile"; then
            echo -e "{{YELLOW}}Platform specified in Containerfile, using compatibility mode{{NORMAL}}"

            # Create temporary Containerfile without platform specification for local build
            temp_containerfile="/tmp/Containerfile.local.$$"
            sed 's/FROM --platform=[^ ]* /FROM /' "$containerfile" > "$temp_containerfile"

            $runtime build -f "$temp_containerfile" -t "$image_name" "$build_context"

            # Clean up temp file
            rm -f "$temp_containerfile"
        else
            $runtime build -f "$containerfile" -t "$image_name" "$build_context"
        fi
    fi

    echo -e "{{GREEN}}✓ Successfully built: $image_name{{NORMAL}}"

# Push project image to registry with smart latest handling
[no-cd]
push project="" tag="":
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"
    tag="{{tag}}"

    # Handle case where user provides tag without project (e.g., "just images push latest")
    if [ -n "$project" ] && [ -z "$tag" ] && [[ "$project" =~ ^(latest|commit-.*|[0-9]+\.[0-9]+.*|v[0-9]+.*)$ ]]; then
        # First parameter looks like a tag, treat it as such
        tag="$project"
        project=""
    fi

    # Auto-discover project if not specified
    if [ -z "$project" ]; then
        echo -e "{{BLUE}}🔍 Auto-discovering project...{{NORMAL}}"
        project=$(just _get_project_name)
        echo -e "{{GREEN}}✓ Using project: $project{{NORMAL}}"
    fi

    # Generate tag if not provided
    if [ -z "$tag" ]; then
        tag=$(just _generate_default_tag)
    fi

    runtime=$(just _detect_runtime)

    # Special handling for latest tag
    if [ "$tag" = "latest" ]; then
        echo -e "{{BLUE}}🔍 Latest tag requested - finding existing images to tag...{{NORMAL}}"

        # Get base image name without tag
        image_base=$(just _get_image_name "")

        # Find the commit image that matches the current git commit
        current_commit_tag=$(just _generate_default_tag)
        latest_commit_image=$(just _get_image_name "$current_commit_tag")

        # Check if the current commit image exists
        if ! $runtime images "$latest_commit_image" >/dev/null 2>&1; then
            # Fallback: get the most recent commit-tagged image
            latest_commit_image=$($runtime images | grep "^$image_base" | grep " commit-" | head -1 | awk '{print $1":"$2}' || true)
        fi

        if [ -z "$latest_commit_image" ]; then
            echo "{{BOLD}}{{RED}}Error:{{NORMAL}} No commit-tagged images found to tag as latest" >&2
            echo "{{YELLOW}}Build an image first with: just images build{{NORMAL}}" >&2
            exit 1
        fi


        echo -e "{{BLUE}}Found latest commit image: $latest_commit_image{{NORMAL}}"

        # Tag only the latest commit image as latest
        latest_image_name=$(just _get_image_name "latest")

        # First push the commit-tagged image to registry
        echo -e "{{BLUE}}Pushing commit image: $latest_commit_image{{NORMAL}}"
        $runtime push "$latest_commit_image"

        echo -e "{{BLUE}}📋 Tagging $latest_commit_image as latest{{NORMAL}}"
        $runtime tag "$latest_commit_image" "$latest_image_name"

        echo -e "{{GREEN}}✓ Tagged latest commit image as latest{{NORMAL}}"

        # Push latest tag
        echo -e "{{BLUE}}Pushing latest tag: $latest_image_name{{NORMAL}}"
        $runtime push "$latest_image_name"

        echo -e "{{GREEN}}✓ Successfully pushed both commit and latest tags{{NORMAL}}"
    else
        # Regular tag push
        image_name=$(just _get_image_name "$tag")

        # Check if the image exists locally
        if ! $runtime images "$image_name" >/dev/null 2>&1; then
            echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Image $image_name not found locally" >&2
            echo "{{YELLOW}}Build the image first with: just images build{{NORMAL}}" >&2
            echo "{{YELLOW}}Available images:{{NORMAL}}" >&2
            image_base=$(just _get_image_name "")
            $runtime images | grep "$image_base" || echo "No images found for project: $project" >&2
            exit 1
        fi

        echo -e "{{BLUE}}Pushing image: $image_name{{NORMAL}}"
        $runtime push "$image_name"

        echo -e "{{GREEN}}✓ Successfully pushed: $image_name{{NORMAL}}"
    fi

# Pull project image from registry
[no-cd]
pull project="" tag="latest":
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"
    tag="{{tag}}"

    # Auto-discover project if not specified
    if [ -z "$project" ]; then
        echo -e "{{BLUE}}🔍 Auto-discovering project...{{NORMAL}}"
        project=$(just _get_project_name)
        echo -e "{{GREEN}}✓ Using project: $project{{NORMAL}}"
    fi

    image_name=$(just _get_image_name "$tag")
    runtime=$(just _detect_runtime)

    echo -e "{{BLUE}}Pulling image: $image_name{{NORMAL}}"
    $runtime pull "$image_name"

    echo -e "{{GREEN}}✓ Successfully pulled: $image_name{{NORMAL}}"

# Tag existing image with new tag
[no-cd]
tag source_tag new_tag:
    #!/usr/bin/env bash
    set -euo pipefail

    source_tag="{{source_tag}}"
    new_tag="{{new_tag}}"

    if [ -z "$source_tag" ] || [ -z "$new_tag" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Both source and new tags are required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just images tag commit-abc123 v1.2.3" >&2
        exit 1
    fi

    runtime=$(just _detect_runtime)

    source_image=$(just _get_image_name "$source_tag")
    new_image=$(just _get_image_name "$new_tag")

    # Check if source image exists
    if ! $runtime images "$source_image" >/dev/null 2>&1; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Source image not found: $source_image" >&2
        echo "{{YELLOW}}Available images:{{NORMAL}}" >&2
        image_base=$(just _get_image_name "")
        $runtime images | grep "$image_base" || echo "No images found" >&2
        exit 1
    fi

    echo -e "{{BLUE}}Tagging image: $source_image → $new_image{{NORMAL}}"
    $runtime tag "$source_image" "$new_image"

    echo -e "{{GREEN}}✓ Successfully tagged: $new_image{{NORMAL}}"

# Show image information
[no-cd]
info project="" tag="":
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"
    tag="{{tag}}"

    # Auto-discover project if not specified
    if [ -z "$project" ]; then
        echo -e "{{BLUE}}🔍 Auto-discovering project...{{NORMAL}}"
        project=$(just _get_project_name)
        echo -e "{{GREEN}}✓ Using project: $project{{NORMAL}}"
    fi

    runtime=$(just _detect_runtime)

    if [ -n "$tag" ]; then
        image_name=$(just _get_image_name "$tag")
    else
        image_name=$(just _get_image_name "")
    fi

    echo ""
    echo -e "{{BLUE}}Image information for: $image_name{{NORMAL}}"
    echo ""
    echo -e "{{BLUE}}Configuration:{{NORMAL}}"
    echo -e "{{YELLOW}}Project:{{NORMAL}} $project"
    echo -e "{{YELLOW}}Registry:{{NORMAL}} ${REGISTRY:-ghcr.io}"
    echo -e "{{YELLOW}}Namespace:{{NORMAL}} ${REGISTRY_NAMESPACE:-${GITHUB_USERNAME:-'Not set'}}"
    echo -e "{{YELLOW}}Image Name Override:{{NORMAL}} ${IMAGE_NAME:-'Not set'}"
    echo -e "{{YELLOW}}Default Platforms:{{NORMAL}} ${DEFAULT_PLATFORMS:-linux/amd64,linux/arm64}"
    echo ""

    # Show image details
    if [ -n "$tag" ]; then
        echo -e "{{BLUE}}Local image details:{{NORMAL}}"
        $runtime images "$image_name" 2>/dev/null || echo "Image not found locally: $image_name"
    else
        echo -e "{{BLUE}}All project images:{{NORMAL}}"
        $runtime images | grep "$image_name" 2>/dev/null || echo "No images found for project: $project"
    fi

# List all project images
[no-cd]
list project="":
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"

    # Auto-discover project if not specified
    if [ -z "$project" ]; then
        echo -e "{{BLUE}}🔍 Auto-discovering project...{{NORMAL}}"
        project=$(just _get_project_name)
        echo -e "{{GREEN}}✓ Using project: $project{{NORMAL}}"
    fi

    runtime=$(just _detect_runtime)
    image_base=$(just _get_image_name "")

    echo ""
    echo -e "{{BLUE}}Images for project: $project{{NORMAL}}"
    echo -e "{{BLUE}}Base name: $image_base{{NORMAL}}"
    echo ""

    # List all images for this project
    images=$($runtime images | grep "$image_base" || true)

    if [ -z "$images" ]; then
        echo -e "{{YELLOW}}No images found for project: $project{{NORMAL}}"
        echo -e "{{YELLOW}}Build an image with: just images build{{NORMAL}}"
    else
        echo "REPOSITORY                              TAG              SIZE       CREATED"
        echo "$images"
    fi

# Remove project images with confirmation
[confirm]
[no-cd]
clean project="":
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"

    # Auto-discover project if not specified
    if [ -z "$project" ]; then
        echo -e "{{BLUE}}🔍 Auto-discovering project...{{NORMAL}}"
        project=$(just _get_project_name)
        echo -e "{{GREEN}}✓ Using project: $project{{NORMAL}}"
    fi

    runtime=$(just _detect_runtime)
    image_base=$(just _get_image_name "")

    echo -e "{{YELLOW}}Removing all images for project: $project{{NORMAL}}"

    # Find and remove all images for the project
    images=$($runtime images | grep "^$image_base" | awk '{print $1":"$2}' || true)

    if [ -z "$images" ]; then
        echo -e "{{YELLOW}}No images found for project: $project{{NORMAL}}"
        exit 0
    fi

    echo -e "{{BLUE}}Images to remove:{{NORMAL}}"
    echo "$images"
    echo ""

    echo "$images" | while IFS= read -r image; do
        if [ -n "$image" ]; then
            echo -e "{{BLUE}}Removing: $image{{NORMAL}}"
            $runtime rmi "$image" 2>/dev/null || true
        fi
    done

    echo -e "{{GREEN}}✓ Project images cleaned{{NORMAL}}"

# Build all projects with Containerfiles
[no-cd]
build-all:
    #!/usr/bin/env bash
    set -euo pipefail

    echo -e "{{BLUE}}Building all projects with Containerfiles...{{NORMAL}}"

    # Find all directories with Containerfile or Dockerfile using discovery logic
    projects=""
    has_current_project=false

    # Check current directory first (handles docker/ subfolder case)
    if just _discover_containerfile_in "." >/dev/null 2>&1; then
        current_project=$(just _get_project_name)
        has_current_project=true
        echo -e "{{GREEN}}✓ Found project in current directory: $current_project{{NORMAL}}"
    fi

    # Check subdirectories
    for dir in */; do
        if [ -d "$dir" ]; then
            dir_name="${dir%/}"
            # Skip docker directory to avoid duplicate detection
            if [ "$dir_name" != "docker" ] && just _discover_containerfile_in "$dir_name" >/dev/null 2>&1; then
                projects="$projects $dir_name"
            fi
        fi
    done

    if [ -z "$projects" ] && [ "$has_current_project" = false ]; then
        echo -e "{{YELLOW}}No projects with Containerfile/Dockerfile found{{NORMAL}}"
        exit 0
    fi

    # Show discovered projects
    if [ "$has_current_project" = true ]; then
        echo -e "{{BLUE}}Found projects: $current_project (current directory)$projects{{NORMAL}}"
    else
        echo -e "{{BLUE}}Found projects:$projects{{NORMAL}}"
    fi
    echo ""

    # Build current project first if found
    if [ "$has_current_project" = true ]; then
        echo -e "{{CYAN}}Building project: $current_project (current directory){{NORMAL}}"
        just images build
        echo ""
    fi

    # Build subdirectory projects
    for project in $projects; do
        if [ -n "$project" ]; then
            echo -e "{{CYAN}}Building project: $project{{NORMAL}}"
            just images build "$project"
            echo ""
        fi
    done

    echo -e "{{GREEN}}✓ All projects built successfully{{NORMAL}}"