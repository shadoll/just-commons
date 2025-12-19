# Container images module - comprehensive image management
# Supports multi-architecture builds, flexible naming, and registry operations

# Define custom colors not in Just's native set
DARK_GREY := '\033[2m'   # Dark grey (dim) for optional parameters

alias help := default

# Default recipe - show available commands
[no-cd]
[private]
default:
    #!/usr/bin/env bash
    echo "{{BOLD}}Container Images Commands{{NORMAL}}"
    echo ""
    echo "{{BOLD}}Usage:{{NORMAL}}"
    echo "  just images <command> [project] [tag]"
    echo ""
    echo "{{BOLD}}Parameters:{{NORMAL}}"
    echo -e "  {{YELLOW}}<required>{{NORMAL}}   - Required parameter"
    echo -e "  {{DARK_GREY}}[optional]{{NORMAL}}   - Optional parameter"
    echo ""
    echo -e "  {{DARK_GREY}}[project]{{NORMAL}}    - Project name (if empty, auto-discovers from current directory)"
    echo -e "  {{DARK_GREY}}[tag]{{NORMAL}}        - Image tag (if empty, generates from git commit or timestamp)"
    echo ""
    echo "{{BOLD}}Commands:{{NORMAL}}"
    echo -e "  {{CYAN}}{{BOLD}}build{{NORMAL}}        {{DARK_GREY}}[service] [compose-file] [tag] [no-cache]\033[0m            - Build service(s) using docker-compose or image with multi-architecture support"
    echo -e "  {{CYAN}}{{BOLD}}push{{NORMAL}}         {{DARK_GREY}}[project] [tag]\033[0m            - Push image to registry"
    echo -e "  {{CYAN}}{{BOLD}}pull{{NORMAL}}         {{DARK_GREY}}[project] [tag]\033[0m            - Pull image from registry"
    echo -e "  {{CYAN}}{{BOLD}}tag{{NORMAL}}          {{YELLOW}}<source_tag> <new_tag>{{NORMAL}}     - Tag existing image with new tag"
    echo -e "  {{CYAN}}{{BOLD}}info{{NORMAL}}         {{DARK_GREY}}[service] [compose-file] [tag]\033[0m            - Show container service or image information"
    echo -e "  {{CYAN}}{{BOLD}}list{{NORMAL}}         {{DARK_GREY}}[project]\033[0m                  - List all project images"
    echo -e "  {{CYAN}}{{BOLD}}clean{{NORMAL}}        {{DARK_GREY}}[project]\033[0m                  - Remove project images (with confirmation)"
    echo -e "  {{CYAN}}{{BOLD}}build-all{{NORMAL}}                                  - Build all projects with Containerfiles"
    echo ""
    echo "{{BOLD}}Examples:{{NORMAL}}"
    echo "  just images build                       # Build all services or current project image"
    echo "  just images build suaimi-dev            # Build specific service or project with auto tag"
    echo "  just images build suaimi-dev container/compose.yml  # Build service with specific compose file"
    echo "  just images build myapp v1.0.0          # Build specific project image with version tag"
    echo "  just images build suaimi-dev \"\" \"\" true  # Build service with no-cache"
    echo "  just images push                        # Push current project latest build"
    echo "  just images push latest                 # Push current project as latest"
    echo "  just images list                        # List all images for current project"
    echo "  just images info                        # Show image information for current project"
    echo "  just images info suaimi-dev             # Show container service information"
    echo "  just images info suaimi-dev container/compose.yml  # Show service info with specific compose file"

# Build service(s) using docker-compose or image with multi-architecture support
[no-cd]
build service="" compose-file="" tag="" no-cache="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"
    tag="{{tag}}"
    no_cache="{{no-cache}}"

    # Check if this is container building (service/compose-file provided) or image building
    if [ -n "$service" ] || [ -n "$compose_file" ]; then
        # Container building mode
        compose_cmd=$(just _detect_compose)

        # Auto-discover compose file if not provided
        if [ -z "$compose_file" ]; then
            compose_file=$(just _discover_compose_file)
        fi

        # Build compose file argument
        file_arg=""
        if [ -n "$compose_file" ]; then
            file_arg="-f $compose_file"
        fi

        # Build no-cache argument
        cache_arg=""
        if [ "$no_cache" = "true" ]; then
            cache_arg="--no-cache"
        fi

        if [ -n "$service" ]; then
            echo -e "{{BLUE}}Building service: $service{{NORMAL}}"
            if [ -n "$cache_arg" ]; then
                echo -e "{{YELLOW}}Using no-cache mode{{NORMAL}}"
            fi
            $compose_cmd $file_arg build $cache_arg "$service"
            echo -e "{{GREEN}}✓ Service $service built{{NORMAL}}"
        else
            echo -e "{{BLUE}}Building all services...{{NORMAL}}"
            if [ -n "$cache_arg" ]; then
                echo -e "{{YELLOW}}Using no-cache mode{{NORMAL}}"
            fi
            $compose_cmd $file_arg build $cache_arg
            echo -e "{{GREEN}}✓ All services built{{NORMAL}}"
        fi
    else
        # Image building mode (original functionality)
        project="$service"  # service parameter used as project for backward compatibility

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

        # Auto-discover containerfile
        containerfile_info=$(just _discover_containerfile)
        read -r containerfile project_name build_context <<< "$containerfile_info"

        echo -e "{{GREEN}}✓ Found $containerfile{{NORMAL}}"

        # Build image
        image_name=$(just _get_image_name "$tag")
        echo -e "{{BLUE}}Building image: $image_name{{NORMAL}}"
        echo -e "{{YELLOW}}Using: $containerfile{{NORMAL}}"
        echo -e "{{YELLOW}}Build context: $build_context{{NORMAL}}"

        # Detect platforms
        platforms=$(just _detect_platforms "$containerfile")
        echo -e "{{YELLOW}}Platforms: $platforms{{NORMAL}}"

        runtime=$(just _detect_runtime)

        # Parse platforms into array
        IFS=',' read -ra PLATFORM_ARRAY <<< "$platforms"

        # Remove any existing manifest or conflicting tags
        $runtime manifest rm "$image_name" 2>/dev/null || true
        $runtime rmi "$image_name" 2>/dev/null || true

        # Build each platform
        temp_tags=()
        timestamp=$(date +%s)

        for platform in "${PLATFORM_ARRAY[@]}"; do
            echo -e "{{BLUE}}Building for platform: $platform{{NORMAL}}"

            temp_tag="${image_name}-temp-${timestamp}-${platform//\//-}"
            temp_tags+=("$temp_tag")

            build_args=""
            if [ "$no_cache" = "true" ]; then
                build_args="--no-cache"
                echo -e "{{YELLOW}}Using no-cache mode{{NORMAL}}"
            fi

            $runtime buildx build \
                --platform "$platform" \
                -f "$containerfile" \
                -t "$temp_tag" \
                --load \
                $build_args \
                "$build_context"
        done

        # Create final image (single or multi-platform)
        if [ ${#PLATFORM_ARRAY[@]} -eq 1 ]; then
            # Single platform - just tag the image
            echo -e "{{BLUE}}Tagging single platform image{{NORMAL}}"
            $runtime tag "${temp_tags[0]}" "$image_name"
        else
            # Multi-platform - create manifest
            echo -e "{{BLUE}}Creating multi-platform manifest{{NORMAL}}"
            manifest_cmd="$runtime manifest create $image_name"
            for temp_tag in "${temp_tags[@]}"; do
                manifest_cmd="$manifest_cmd $temp_tag"
            done
            eval "$manifest_cmd"
        fi

        # Keep platform images for manifest - don't clean up temp tags

        echo -e "{{GREEN}}✓ Successfully built: $image_name{{NORMAL}}"
    fi

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

        # First push the commit image/manifest
        if $runtime manifest inspect "$latest_commit_image" >/dev/null 2>&1; then
            echo -e "{{BLUE}}Pushing multi-platform manifest: $latest_commit_image{{NORMAL}}"

            # For manifests, we need to push all referenced platform images first
            platform_images=$($runtime manifest inspect "$latest_commit_image" | grep -o '"[^"]*-temp-[^"]*"' | tr -d '"' | sort -u || true)

            for platform_image in $platform_images; do
                if [ -n "$platform_image" ]; then
                    echo -e "{{BLUE}}Pushing platform image: $platform_image{{NORMAL}}"
                    $runtime push "$platform_image"
                fi
            done

            # Tag the manifest with latest before pushing
            echo -e "{{BLUE}}📋 Tagging manifest as latest{{NORMAL}}"
            $runtime tag "$latest_commit_image" "$latest_image_name"

            # Push both tags (they point to the same manifest)
            echo -e "{{BLUE}}Pushing commit manifest: $latest_commit_image{{NORMAL}}"
            $runtime manifest push "$latest_commit_image"

            echo -e "{{BLUE}}Pushing latest manifest: $latest_image_name{{NORMAL}}"
            $runtime manifest push "$latest_image_name"
        else
            echo -e "{{BLUE}}Pushing commit image: $latest_commit_image{{NORMAL}}"
            $runtime push "$latest_commit_image"

            # For regular images, just tag and push
            echo -e "{{BLUE}}📋 Tagging $latest_commit_image as latest{{NORMAL}}"
            $runtime tag "$latest_commit_image" "$latest_image_name"

            echo -e "{{BLUE}}Pushing latest tag: $latest_image_name{{NORMAL}}"
            $runtime push "$latest_image_name"
        fi

        echo -e "{{GREEN}}✓ Successfully pushed both commit and latest tags{{NORMAL}}"
    else
        # Regular tag push - push existing image
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

        # Check if this is a manifest (multi-platform) or regular image
        if $runtime manifest inspect "$image_name" >/dev/null 2>&1; then
            echo -e "{{BLUE}}Pushing multi-platform manifest: $image_name{{NORMAL}}"

            # For manifests, we need to push all referenced platform images first
            platform_images=$($runtime manifest inspect "$image_name" | grep -o '"[^"]*-temp-[^"]*"' | tr -d '"' | sort -u || true)

            for platform_image in $platform_images; do
                if [ -n "$platform_image" ]; then
                    echo -e "{{BLUE}}Pushing platform image: $platform_image{{NORMAL}}"
                    $runtime push "$platform_image"
                fi
            done

            # Now push the manifest
            $runtime manifest push "$image_name"
        else
            echo -e "{{BLUE}}Pushing image: $image_name{{NORMAL}}"
            $runtime push "$image_name"
        fi

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

# Show image information or container service information
[no-cd]
info service="" compose-file="" tag="":
    #!/usr/bin/env bash
    set -euo pipefail

    service="{{service}}"
    compose_file="{{compose-file}}"
    tag="{{tag}}"

    # Check if this is container info (service/compose-file provided) or image info
    if [ -n "$service" ] || [ -n "$compose_file" ]; then
        # Container info mode
        compose_cmd=$(just _detect_compose)

        # Auto-discover compose file if not provided
        if [ -z "$compose_file" ]; then
            compose_file=$(just _discover_compose_file)
        fi

        # Build compose file argument
        file_arg=""
        if [ -n "$compose_file" ]; then
            file_arg="-f $compose_file"
        fi

        echo ""
        echo -e "{{BLUE}}Container Service Information{{NORMAL}}"
        echo -e "{{YELLOW}}Compose file:{{NORMAL}} $compose_file"
        echo ""

        if [ -n "$service" ]; then
            echo -e "{{BLUE}}Service details for: $service{{NORMAL}}"
            echo ""

            # Get service configuration
            service_config=$($compose_cmd $file_arg config --services | grep "^$service$" || true)
            if [ -z "$service_config" ]; then
                echo -e "{{RED}}Service '$service' not found in compose file{{NORMAL}}"
                echo -e "{{YELLOW}}Available services:{{NORMAL}}"
                $compose_cmd $file_arg config --services
                exit 1
            fi

            # Show service configuration
            echo -e "{{CYAN}}Configuration:{{NORMAL}}"
            $compose_cmd $file_arg config | sed -n "/^  $service:/,/^  [^ ]/p" | sed '$d' | sed 's/^/  /'
        else
            echo -e "{{BLUE}}All services in compose file:{{NORMAL}}"
            echo ""
            services=$($compose_cmd $file_arg config --services)
            if [ -z "$services" ]; then
                echo -e "{{YELLOW}}No services found in compose file{{NORMAL}}"
            else
                echo "$services" | while IFS= read -r svc; do
                    echo -e "{{CYAN}}• $svc{{NORMAL}}"
                done
                echo ""
                echo -e "{{YELLOW}}Use: just images info <service_name> to see detailed configuration{{NORMAL}}"
            fi
        fi
    else
        # Image info mode (original functionality)
        project="$service"  # service parameter used as project for backward compatibility

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
