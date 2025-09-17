#!/usr/bin/env bash

# POM Version Updater Script
# Updates version in pom.xml file with proper validation and backup

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

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
POM_PATH="$REPO_ROOT/pom.xml"

# Function to validate version format
validate_version() {
    local version=$1
    
    # Check semantic versioning format
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
        print_error "Invalid version format: $version"
        print_error "Expected format: MAJOR.MINOR.PATCH[-QUALIFIER]"
        return 1
    fi
    
    return 0
}

# Function to get current version from pom.xml
get_current_version() {
    if [ ! -f "$POM_PATH" ]; then
        print_error "pom.xml not found at $POM_PATH"
        exit 1
    fi
    
    local version=""
    
    # Try multiple approaches to extract version
    if command -v xmllint > /dev/null 2>&1; then
        # Using xmllint (most reliable)
        version=$(xmllint --xpath "string(/project/version)" "$POM_PATH" 2>/dev/null || echo "")
        if [ -z "$version" ]; then
            # Try to get from parent if project version is empty
            version=$(xmllint --xpath "string(/project/parent/version)" "$POM_PATH" 2>/dev/null || echo "")
        fi
    fi
    
    # Fallback to awk/sed if xmllint not available
    if [ -z "$version" ]; then
        version=$(awk '
        /<project[^>]*>/ { in_project = 1; next }
        /<parent>/ { if (in_project) in_parent = 1; next }
        /<\/parent>/ { in_parent = 0; next }
        /<version>/ {
            if (in_project && !in_parent && !found_version) {
                gsub(/<[^>]*>/, "")
                gsub(/^[[:space:]]+|[[:space:]]+$/, "")
                if (length($0) > 0) {
                    found_version = 1
                    print $0
                    exit
                }
            }
        }
        ' "$POM_PATH")
    fi
    
    if [ -z "$version" ]; then
        print_error "Could not extract version from pom.xml"
        return 1
    fi
    
    echo "$version"
}

# Function to update version in pom.xml
update_version_in_pom() {
    local new_version=$1
    local add_snapshot=${2:-true}
    
    if [ "$add_snapshot" = true ]; then
        new_version="${new_version}-SNAPSHOT"
    fi
    
    # Create backup
    local backup_file="${POM_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$POM_PATH" "$backup_file"
    print_info "Created backup: $backup_file"
    
    # Update version using multiple approaches for compatibility
    local updated=false
    
    if command -v xmllint > /dev/null 2>&1 && command -v xmlstarlet > /dev/null 2>&1; then
        # Using xmlstarlet (most reliable for XML editing)
        xmlstarlet ed -L -N pom="http://maven.apache.org/POM/4.0.0" \
            -u "/pom:project/pom:version" -v "$new_version" "$POM_PATH" 2>/dev/null && updated=true
    fi
    
    if [ "$updated" = false ]; then
        # Fallback to sed - update first occurrence of <version> that's not in <parent>
        local temp_file=$(mktemp)
        awk -v new_version="$new_version" '
        /<project[^>]*>/ { in_project = 1 }
        /<parent>/ { if (in_project) in_parent = 1 }
        /<\/parent>/ { in_parent = 0 }
        /<version>/ {
            if (in_project && !in_parent && !updated_version) {
                gsub(/<version>[^<]*<\/version>/, "<version>" new_version "</version>")
                updated_version = 1
            }
        }
        { print }
        ' "$POM_PATH" > "$temp_file"
        
        if [ -s "$temp_file" ]; then
            mv "$temp_file" "$POM_PATH"
            updated=true
        else
            rm -f "$temp_file"
        fi
    fi
    
    if [ "$updated" = false ]; then
        print_error "Failed to update version in pom.xml"
        print_info "Restoring from backup..."
        mv "$backup_file" "$POM_PATH"
        return 1
    fi
    
    # Verify the update
    local verification_version=$(get_current_version)
    if [ "$verification_version" = "$new_version" ]; then
        print_info "Successfully updated version to: $new_version"
        rm -f "$backup_file"
        return 0
    else
        print_error "Version update verification failed"
        print_error "Expected: $new_version, Found: $verification_version"
        print_info "Restoring from backup..."
        mv "$backup_file" "$POM_PATH"
        return 1
    fi
}

# Function to increment version based on semver rules
increment_version() {
    local version=$1
    local bump_type=$2
    
    # Remove any qualifiers (-SNAPSHOT, etc.)
    local base_version=$(echo "$version" | sed 's/-.*$//')
    
    # Split version into parts
    IFS='.' read -ra VERSION_PARTS <<< "$base_version"
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
            print_error "Invalid bump type: $bump_type (must be major, minor, or patch)"
            return 1
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Main function
main() {
    local new_version=""
    local bump_type=""
    local no_snapshot=false
    local dry_run=false
    local help=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                new_version="$2"
                shift 2
                ;;
            --bump-major)
                bump_type="major"
                shift
                ;;
            --bump-minor)
                bump_type="minor"
                shift
                ;;
            --bump-patch)
                bump_type="patch"
                shift
                ;;
            --no-snapshot)
                no_snapshot=true
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
        echo "Updates version in pom.xml file with proper validation and backup"
        echo ""
        echo "Options:"
        echo "  --version VERSION    Set specific version"
        echo "  --bump-major         Increment major version"
        echo "  --bump-minor         Increment minor version"
        echo "  --bump-patch         Increment patch version"
        echo "  --no-snapshot        Don't append -SNAPSHOT to version"
        echo "  --dry-run            Show what would be done without making changes"
        echo "  -h, --help           Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 --version 1.2.3"
        echo "  $0 --bump-minor"
        echo "  $0 --version 1.0.0 --no-snapshot"
        exit 0
    fi
    
    # Validate input
    if [ -z "$new_version" ] && [ -z "$bump_type" ]; then
        print_error "Must specify either --version or a bump type (--bump-major, --bump-minor, --bump-patch)"
        exit 1
    fi
    
    if [ -n "$new_version" ] && [ -n "$bump_type" ]; then
        print_error "Cannot specify both --version and a bump type"
        exit 1
    fi
    
    # Get current version
    local current_version=$(get_current_version)
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    local current_base_version=$(echo "$current_version" | sed 's/-.*$//')
    print_info "Current version: $current_version"
    
    # Determine new version
    if [ -n "$bump_type" ]; then
        new_version=$(increment_version "$current_base_version" "$bump_type")
        if [ $? -ne 0 ]; then
            exit 1
        fi
        print_info "Bumping $bump_type version: $current_base_version → $new_version"
    else
        # Remove any existing qualifiers from provided version
        new_version=$(echo "$new_version" | sed 's/-.*$//')
        print_info "Setting specific version: $current_base_version → $new_version"
    fi
    
    # Validate new version
    if ! validate_version "$new_version"; then
        exit 1
    fi
    
    # Determine final version with/without snapshot
    local final_version="$new_version"
    if [ "$no_snapshot" = false ]; then
        final_version="${new_version}-SNAPSHOT"
    fi
    
    echo ""
    echo -e "${BLUE}Version Update Summary:${NC}"
    echo "  Current: $current_version"
    echo "  New:     $final_version"
    if [ -n "$bump_type" ]; then
        echo "  Type:    $bump_type version bump"
    else
        echo "  Type:    specific version set"
    fi
    echo ""
    
    if [ "$dry_run" = true ]; then
        print_info "Dry run mode - no changes made"
        exit 0
    fi
    
    # Confirm if not in automation mode
    if [ -t 0 ] && [ -z "${CI:-}" ]; then
        echo -n "Continue with version update? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_info "Version update cancelled"
            exit 0
        fi
    fi
    
    # Update version
    local add_snapshot=true
    if [ "$no_snapshot" = true ]; then
        add_snapshot=false
    fi
    
    if update_version_in_pom "$new_version" "$add_snapshot"; then
        print_info "Version update completed successfully!"
        echo ""
        echo -e "${GREEN}✅ pom.xml version updated to: $final_version${NC}"
    else
        print_error "Version update failed!"
        exit 1
    fi
}

# Check dependencies
if ! command -v git > /dev/null 2>&1; then
    print_warn "git not found - using current directory as repo root"
    REPO_ROOT=$(pwd)
    POM_PATH="$REPO_ROOT/pom.xml"
fi

main "$@"
