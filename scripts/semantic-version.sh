#!/usr/bin/env bash

# Semantic Versioning Script for Maven Projects
# Analyzes commits since last tag to determine version bump
# Follows conventional commit standards

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository!"
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
POM_PATH="$REPO_ROOT/pom.xml"

# Function to get current version from pom.xml
get_current_version() {
    if [ ! -f "$POM_PATH" ]; then
        print_error "pom.xml not found at $POM_PATH"
        exit 1
    fi
    
    # Extract version, handling both project version and inherited parent version
    local version=$(xmllint --xpath "string(/project/version)" "$POM_PATH" 2>/dev/null)
    if [ -z "$version" ]; then
        version=$(xmllint --xpath "string(/project/parent/version)" "$POM_PATH" 2>/dev/null)
    fi
    
    # Remove -SNAPSHOT suffix for processing
    echo "$version" | sed 's/-SNAPSHOT//'
}

# Function to increment version based on semver rules
increment_version() {
    local version=$1
    local bump_type=$2
    
    # Split version into parts
    IFS='.' read -ra VERSION_PARTS <<< "$version"
    local major=${VERSION_PARTS[0]:-0}
    local minor=${VERSION_PARTS[1]:-0}
    local patch=${VERSION_PARTS[2]:-0}
    
    case $bump_type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
        *)
            print_error "Invalid bump type: $bump_type"
            exit 1
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Function to analyze commits and determine version bump
analyze_commits() {
    local last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    local commit_range
    
    if [ -z "$last_tag" ]; then
        # No tags found, analyze all commits
        commit_range="HEAD"
        print_info "No previous tags found, analyzing all commits"
    else
        # Analyze commits since last tag
        commit_range="$last_tag..HEAD"
        print_info "Analyzing commits since tag: $last_tag"
    fi
    
    # Get all commit messages in the range
    local commits=$(git log "$commit_range" --pretty=format:"%s" 2>/dev/null || echo "")
    
    if [ -z "$commits" ]; then
        echo "none"
        return
    fi
    
    local has_breaking=false
    local has_feat=false
    local has_fix=false
    
    while IFS= read -r commit; do
        # Check for breaking changes
        if [[ "$commit" =~ ^[a-z]+(\(.+\))?!:|BREAKING[[:space:]]CHANGE:|^[a-z]+!:|!: ]]; then
            has_breaking=true
            print_info "Found breaking change: $commit"
        # Check for features
        elif [[ "$commit" =~ ^feat(\(.+\))?: ]]; then
            has_feat=true
            print_info "Found feature: $commit"
        # Check for fixes
        elif [[ "$commit" =~ ^fix(\(.+\))?: ]]; then
            has_fix=true
            print_info "Found fix: $commit"
        fi
    done <<< "$commits"
    
    # Determine bump type based on conventional commit analysis
    if [ "$has_breaking" = true ]; then
        echo "major"
    elif [ "$has_feat" = true ]; then
        echo "minor"
    elif [ "$has_fix" = true ]; then
        echo "patch"
    else
        echo "none"
    fi
}

# Function to update version in pom.xml
update_pom_version() {
    local new_version=$1
    local snapshot_version="${new_version}-SNAPSHOT"
    
    # Create backup
    cp "$POM_PATH" "$POM_PATH.backup"
    
    # Update version in pom.xml
    if command -v xmllint > /dev/null 2>&1; then
        # Use xmllint if available (more reliable)
        sed -i.bak "s|<version>[^<]*</version>|<version>$snapshot_version</version>|" "$POM_PATH"
        rm "$POM_PATH.bak"
    else
        # Fallback to sed with more specific pattern
        sed -i.bak "0,/<version>[^<]*<\/version>/s/<version>[^<]*<\/version>/<version>$snapshot_version<\/version>/" "$POM_PATH"
        rm "$POM_PATH.bak"
    fi
    
    print_info "Updated pom.xml version to: $snapshot_version"
}

# Main function
main() {
    local force_bump=""
    local dry_run=false
    local help=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force-major)
                force_bump="major"
                shift
                ;;
            --force-minor)
                force_bump="minor"
                shift
                ;;
            --force-patch)
                force_bump="patch"
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            -h|--help)
                help=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                help=true
                shift
                ;;
        esac
    done
    
    if [ "$help" = true ]; then
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Analyzes commits using conventional commit standards and updates version in pom.xml"
        echo ""
        echo "Options:"
        echo "  --force-major    Force a major version bump"
        echo "  --force-minor    Force a minor version bump" 
        echo "  --force-patch    Force a patch version bump"
        echo "  --dry-run        Show what would be done without making changes"
        echo "  -h, --help       Show this help message"
        echo ""
        echo "Commit message conventions:"
        echo "  feat: new feature (minor version bump)"
        echo "  fix: bug fix (patch version bump)"
        echo "  BREAKING CHANGE: or ! suffix (major version bump)"
        echo "  docs:, style:, refactor:, test: (no version bump)"
        exit 0
    fi
    
    local current_version=$(get_current_version)
    print_info "Current version: $current_version"
    
    local bump_type
    if [ -n "$force_bump" ]; then
        bump_type=$force_bump
        print_info "Forced bump type: $bump_type"
    else
        bump_type=$(analyze_commits)
        print_info "Determined bump type: $bump_type"
    fi
    
    if [ "$bump_type" = "none" ]; then
        print_warn "No version bump needed based on commit analysis"
        echo "Current version remains: $current_version-SNAPSHOT"
        exit 0
    fi
    
    local new_version=$(increment_version "$current_version" "$bump_type")
    
    echo ""
    echo -e "${BLUE}Version Update Summary:${NC}"
    echo "  Current: $current_version-SNAPSHOT"
    echo "  New:     $new_version-SNAPSHOT"
    echo "  Bump:    $bump_type"
    echo ""
    
    if [ "$dry_run" = true ]; then
        print_info "Dry run mode - no changes made"
        exit 0
    fi
    
    # Update pom.xml
    update_pom_version "$new_version"
    
    # Output new version for use by other scripts
    echo "$new_version"
}

# Check dependencies
if ! command -v git > /dev/null 2>&1; then
    print_error "git is required but not installed"
    exit 1
fi

main "$@"
