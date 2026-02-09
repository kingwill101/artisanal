# List available commands
default:
    @just --list

# Serve the landing page locally (requires Python 3)
landing:
    #!/usr/bin/env bash
    port=$((8000 + RANDOM % 1000))
    echo "Serving landing page at http://localhost:$port"
    cd landing && python3 -m http.server $port

# Build the blog with Hugo
blog:
    cd blog-hugo && hugo --minify

# Interactive release workflow - updates README, commits, and creates tag
release:
    #!/usr/bin/env bash
    set -euo pipefail

    # Get the latest tag
    latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    echo "Current version: $latest_tag"

    # Parse version numbers (strip 'v' prefix)
    version=${latest_tag#v}
    IFS='.' read -r major minor patch <<< "$version"

    # Show options
    echo ""
    echo "Select release type:"
    echo "  1) patch    → v$major.$minor.$((patch + 1))"
    echo "  2) minor    → v$major.$((minor + 1)).0"
    echo "  3) major    → v$((major + 1)).0.0"
    echo "  4) custom   → enter custom version"
    echo "  5) override → $latest_tag (re-push existing tag)"
    echo "  6) cancel"
    echo ""

    read -p "Choice [1-6]: " choice

    case $choice in
        1) new_version="v$major.$minor.$((patch + 1))" ;;
        2) new_version="v$major.$((minor + 1)).0" ;;
        3) new_version="v$((major + 1)).0.0" ;;
        4)
            read -p "Enter custom version (e.g., 1.2.3): " custom_ver
            # Strip 'v' prefix if provided
            custom_ver=${custom_ver#v}
            new_version="v$custom_ver"
            ;;
        5) new_version="$latest_tag"; override=true ;;
        6) echo "Cancelled."; exit 0 ;;
        *) echo "Invalid choice."; exit 1 ;;
    esac

    echo ""

    # Strip 'v' prefix for version number
    version_number=${new_version#v}

    if [[ "${override:-false}" == "true" ]]; then
        read -p "Delete and re-push tag $new_version? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            git tag -d "$new_version"
            git push origin --delete "$new_version"
            git tag "$new_version"
            git push origin "$new_version"
            echo "✓ Re-released $new_version"
        else
            echo "Cancelled."
        fi
    else
        read -p "Release $new_version? (updates README, commits, tags, pushes) [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            # Update version in pubspec.yaml
            echo "Updating pubspec.yaml..."
            sed -i '' -E "s/^version: [0-9]+\.[0-9]+\.[0-9]+/version: $version_number/" pubspec.yaml

            # Update version in README.md
            echo "Updating README.md..."
            sed -i '' -E "s/nocterm: \^[0-9]+\.[0-9]+\.[0-9]+/nocterm: ^$version_number/" README.md
            sed -i '' -E "s/in early development \([0-9]+\.[0-9]+\.[0-9]+\)/in early development ($version_number)/" README.md

            # Commit the version bump
            git add pubspec.yaml README.md
            git commit -m "chore: bump version to $version_number"

            # Push the commit
            git push origin main

            # Create and push the tag
            git tag "$new_version"
            git push origin "$new_version"

            echo "✓ Released $new_version"
        else
            echo "Cancelled."
        fi
    fi
