# Universal container image operations

# Build project image (auto-discovers Dockerfile if project not specified)
[no-cd]
build project="" tag="":
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"
    tag="{{tag}}"

    # Determine discovery directory
    if [ -z "$project" ]; then
        discovery_dir="."
        echo -e "{{BLUE}}🔍 Auto-discovering Dockerfile/Containerfile...{{NORMAL}}"
    else
        # Check if project directory exists
        if [ ! -d "$project" ]; then
            echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Project directory '$project' not found" >&2
            exit 1
        fi
        discovery_dir="$project"
        echo -e "{{BLUE}}🔍 Auto-discovering Dockerfile/Containerfile in $project...{{NORMAL}}"
    fi

    # Use unified discovery logic
    discovery_result=$(just _discover_containerfile_in "$discovery_dir")
    read -r containerfile discovered_project build_context <<< "$discovery_result"

    # Use discovered project name if not explicitly set
    if [ -z "$project" ]; then
        project="$discovered_project"
    fi

    echo -e "{{GREEN}}✓ Found $containerfile{{NORMAL}}"

    # Generate tag if not provided
    if [ -z "$tag" ]; then
        if git rev-parse --git-dir >/dev/null 2>&1; then
            tag="commit-$(git rev-parse --short HEAD)"
        else
            tag="build-$(date '+%Y%m%d-%H%M%S')"
        fi
    fi

    runtime=$(just _detect_runtime)
    registry="${REGISTRY:-ghcr.io}"
    username="${GITHUB_USERNAME:-}"

    if [ -n "$username" ]; then
        image_name="$registry/$username/$project:$tag"
    else
        image_name="$project:$tag"
    fi

    echo -e "{{BLUE}}Building image: $image_name{{NORMAL}}"
    echo -e "{{YELLOW}}Using: $containerfile{{NORMAL}}"
    echo -e "{{YELLOW}}Build context: $build_context{{NORMAL}}"

    # Handle cross-platform builds with macOS compatibility workaround
    if grep -q "FROM.*--platform" "$containerfile"; then
        echo -e "{{YELLOW}}Cross-platform build detected, using macOS compatibility workaround{{NORMAL}}"

        # Create temporary Containerfile without platform specification for local build
        temp_containerfile="/tmp/Containerfile.local.$$"
        sed 's/FROM --platform=[^ ]* /FROM /' "$containerfile" > "$temp_containerfile"

        echo -e "{{BLUE}}Building without platform emulation (will be multi-arch compatible){{NORMAL}}"
        $runtime build -f "$temp_containerfile" -t "$image_name" --load "$build_context"

        # Clean up temp file
        rm -f "$temp_containerfile"
    else
        $runtime build -f "$containerfile" -t "$image_name" --load "$build_context"
    fi

    echo -e "{{GREEN}}✓ Successfully built: $image_name{{NORMAL}}"

# Push project image to registry
[no-cd]
push project="" tag="":
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"
    tag="{{tag}}"

    # Auto-discover project if not specified
    if [ -z "$project" ]; then
        echo -e "{{BLUE}}🔍 Auto-discovering project...{{NORMAL}}"
        project=$(just _discover_project)
        echo -e "{{GREEN}}✓ Using project: $project{{NORMAL}}"
    fi

    # Generate tag if not provided
    if [ -z "$tag" ]; then
        if git rev-parse --git-dir >/dev/null 2>&1; then
            tag="commit-$(git rev-parse --short HEAD)"
        else
            tag="latest"
        fi
    fi

    runtime=$(just _detect_runtime)
    registry="${REGISTRY:-ghcr.io}"
    username="${GITHUB_USERNAME:-}"

    if [ -z "$username" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} GITHUB_USERNAME not set" >&2
        echo "{{YELLOW}}Set GITHUB_USERNAME in .env file{{NORMAL}}" >&2
        exit 1
    fi

    image_name="$registry/$username/$project:$tag"

    echo -e "{{BLUE}}Pushing image: $image_name{{NORMAL}}"
    $runtime push "$image_name"

    echo -e "{{GREEN}}✓ Successfully pushed: $image_name{{NORMAL}}"

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
        project=$(just _discover_project)
        echo -e "{{GREEN}}✓ Using project: $project{{NORMAL}}"
    fi

    runtime=$(just _detect_runtime)
    registry="${REGISTRY:-ghcr.io}"
    username="${GITHUB_USERNAME:-}"

    if [ -z "$username" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} GITHUB_USERNAME not set" >&2
        echo "{{YELLOW}}Set GITHUB_USERNAME in .env file{{NORMAL}}" >&2
        exit 1
    fi

    image_name="$registry/$username/$project:$tag"

    echo -e "{{BLUE}}Pulling image: $image_name{{NORMAL}}"
    $runtime pull "$image_name"

    echo -e "{{GREEN}}✓ Successfully pulled: $image_name{{NORMAL}}"

# Tag existing image
[no-cd]
tag project new_tag:
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"
    new_tag="{{new_tag}}"

    if [ -z "$project" ] || [ -z "$new_tag" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Project name and new tag are required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just images tag myproject newtag" >&2
        exit 1
    fi

    runtime=$(just _detect_runtime)
    registry="${REGISTRY:-ghcr.io}"
    username="${GITHUB_USERNAME:-}"

    if [ -n "$username" ]; then
        old_image="$registry/$username/$project"
        new_image="$registry/$username/$project:$new_tag"
    else
        old_image="$project"
        new_image="$project:$new_tag"
    fi

    # Find the most recent tag for the project
    latest_image=$($runtime images | grep "^$old_image" | awk '{print $1":"$2}' | head -1)

    if [ -z "$latest_image" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} No images found for project: $project" >&2
        exit 1
    fi

    echo -e "{{BLUE}}Tagging image: $latest_image → $new_image{{NORMAL}}"
    $runtime tag "$latest_image" "$new_image"

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
        project=$(just _discover_project)
        echo -e "{{GREEN}}✓ Using project: $project{{NORMAL}}"
    fi

    runtime=$(just _detect_runtime)
    registry="${REGISTRY:-ghcr.io}"
    username="${GITHUB_USERNAME:-}"

    if [ -n "$username" ]; then
        image_base="$registry/$username/$project"
    else
        image_base="$project"
    fi

    if [ -n "$tag" ]; then
        image_name="$image_base:$tag"
    else
        image_name="$image_base"
    fi

    echo ""
    echo -e "{{BLUE}}Image information for: $image_name{{NORMAL}}"

    # Show image details
    $runtime images "$image_name"

    echo ""
    echo -e "{{BLUE}}Image history:{{NORMAL}}"
    $runtime history "$image_name" 2>/dev/null || echo "Image not found locally"

# Remove project images
[confirm]
[no-cd]
clean project="":
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"

    # Auto-discover project if not specified
    if [ -z "$project" ]; then
        echo -e "{{BLUE}}🔍 Auto-discovering project...{{NORMAL}}"
        project=$(just _discover_project)
        echo -e "{{GREEN}}✓ Using project: $project{{NORMAL}}"
    fi

    runtime=$(just _detect_runtime)
    registry="${REGISTRY:-ghcr.io}"
    username="${GITHUB_USERNAME:-}"

    if [ -n "$username" ]; then
        image_pattern="$registry/$username/$project"
    else
        image_pattern="$project"
    fi

    echo -e "{{YELLOW}}Removing all images for project: $project{{NORMAL}}"

    # Find and remove all images for the project
    images=$($runtime images --format "{{{{.Repository}}}}:{{{{.Tag}}}}" | grep "^$image_pattern" || true)

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

# Build all known projects
[no-cd]
build-all:
    #!/usr/bin/env bash
    set -euo pipefail

    echo -e "{{BLUE}}Building all projects with Containerfiles...{{NORMAL}}"

    # Find all directories with Containerfile or Dockerfile using discovery logic
    projects=""

    # Check current directory first (handles docker/ subfolder case)
    has_current_project=false
    if just _discover_containerfile_in "." >/dev/null 2>&1; then
        current_project=$(just _discover_project)
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
