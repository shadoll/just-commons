# Universal container image operations

# Build project image
[group('images')]
build project tag="":
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"
    tag="{{tag}}"

    if [ -z "$project" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Project name is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just images build myproject [tag]" >&2
        exit 1
    fi

    # Check if project directory exists
    if [ ! -d "$project" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Project directory '$project' not found" >&2
        exit 1
    fi

    # Check for Containerfile or Dockerfile
    containerfile=""
    if [ -f "$project/Containerfile" ]; then
        containerfile="$project/Containerfile"
    elif [ -f "$project/Dockerfile" ]; then
        containerfile="$project/Dockerfile"
    else
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} No Containerfile or Dockerfile found in $project/" >&2
        exit 1
    fi

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

    $runtime build -f "$containerfile" -t "$image_name" "$project/"

    echo -e "{{GREEN}}✓ Successfully built: $image_name{{NORMAL}}"

# Push project image to registry
[group('images')]
push project tag="":
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"
    tag="{{tag}}"

    if [ -z "$project" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Project name is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just images push myproject [tag]" >&2
        exit 1
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
[group('images')]
pull project tag="latest":
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"
    tag="{{tag}}"

    if [ -z "$project" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Project name is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just images pull myproject [tag]" >&2
        exit 1
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
[group('images')]
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
    latest_image=$($runtime images --format "table {{{{.Repository}}}}:{{{{.Tag}}}}" | grep "^$old_image" | head -1)

    if [ -z "$latest_image" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} No images found for project: $project" >&2
        exit 1
    fi

    echo -e "{{BLUE}}Tagging image: $latest_image → $new_image{{NORMAL}}"
    $runtime tag "$latest_image" "$new_image"

    echo -e "{{GREEN}}✓ Successfully tagged: $new_image{{NORMAL}}"

# Show image information
[group('images')]
info project tag="":
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"
    tag="{{tag}}"

    if [ -z "$project" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Project name is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just images info myproject [tag]" >&2
        exit 1
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

    echo -e "{{BLUE}}Image information for: $image_name{{NORMAL}}"
    echo ""

    # Show image details
    $runtime images "$image_name" --format "table {{{{.Repository}}}}\\t{{{{.Tag}}}}\\t{{{{.ID}}}}\\t{{{{.CreatedSince}}}}\\t{{{{.Size}}}}"

    echo ""
    echo -e "{{BLUE}}Image history:{{NORMAL}}"
    $runtime history "$image_name" 2>/dev/null || echo "Image not found locally"

# Remove project images
[group('images')]
[confirm]
clean project:
    #!/usr/bin/env bash
    set -euo pipefail

    project="{{project}}"

    if [ -z "$project" ]; then
        echo "{{BOLD}}{{RED}}Error:{{NORMAL}} Project name is required" >&2
        echo "{{YELLOW}}Usage:{{NORMAL}} just images clean myproject" >&2
        exit 1
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
[group('images')]
build-all:
    #!/usr/bin/env bash
    set -euo pipefail

    echo -e "{{BLUE}}Building all projects with Containerfiles...{{NORMAL}}"

    # Find all directories with Containerfile or Dockerfile
    projects=""
    for dir in */; do
        if [ -f "${dir}Containerfile" ] || [ -f "${dir}Dockerfile" ]; then
            project_name="${dir%/}"
            projects="$projects $project_name"
        fi
    done

    if [ -z "$projects" ]; then
        echo -e "{{YELLOW}}No projects with Containerfile/Dockerfile found{{NORMAL}}"
        exit 0
    fi

    echo -e "{{BLUE}}Found projects:$projects{{NORMAL}}"
    echo ""

    for project in $projects; do
        echo -e "{{CYAN}}Building project: $project{{NORMAL}}"
        just images build "$project"
        echo ""
    done

    echo -e "{{GREEN}}✓ All projects built successfully{{NORMAL}}"