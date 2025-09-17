#!/usr/bin/env bash

# Enhanced Changelog Generator for Maven Projects
# Generates changelog from git commits using conventional commit standards
# Integrates with semantic versioning workflow

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

REPO_ROOT=$(git rev-parse --show-toplevel)
DEFAULT_OUTPUT="CHANGELOG.md"
OUTPUT_FILE="$REPO_ROOT/${1:-$DEFAULT_OUTPUT}"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository!"
    exit 1
fi

# Function to get current version from pom.xml
get_current_version() {
    local pom_path="$REPO_ROOT/pom.xml"
    if [ ! -f "$pom_path" ]; then
        echo "0.0.0"
        return
    fi
    
    # Extract version using multiple methods
    local version=""
    
    # Try xmllint first (more reliable)
    if command -v xmllint > /dev/null 2>&1; then
        version=$(xmllint --xpath "string(/project/version)" "$pom_path" 2>/dev/null || echo "")
    fi
    
    # Fallback to sed/awk if xmllint not available or failed
    if [ -z "$version" ]; then
        version=$(awk '/<project[^>]*>/{project=1} project && /<version>/{gsub(/<[^>]*>/, ""); if(!parent_version && !found_version) {found_version=1; print; exit}} /<parent>/{parent=1} parent && /<version>/{parent_version=$0} /<\/parent>/{parent=0}' "$pom_path")
    fi
    
    # Clean up version (remove whitespace and -SNAPSHOT)
    version=$(echo "$version" | sed -E 's/^\s+|\s+$//g' | sed 's/-SNAPSHOT//')
    
    if [ -z "$version" ]; then
        version="0.0.0"
    fi
    
    echo "$version"
}

# Function to categorize commit messages
categorize_commit() {
    local subject=$1
    local hash=$2
    local author=$3
    local date=$4
    
    # Clean subject and extract scope if present
    local clean_subject=$(echo "$subject" | sed -E 's/^[a-z]+(\([^)]+\))?!?:\s*//')
    local scope=""
    
    # Extract scope using sed instead of bash regex
    local extracted_scope=$(echo "$subject" | sed -n 's/.*(\([^)]*\)).*/\1/p')
    if [ -n "$extracted_scope" ]; then
        scope=" ($extracted_scope)"
    fi
    
    case "$subject" in
        feat*)
            echo "FEATURE|$clean_subject$scope|$author|$hash"
            ;;
        fix*)
            echo "BUGFIX|$clean_subject$scope|$author|$hash"
            ;;
        docs*)
            echo "DOCS|$clean_subject$scope|$author|$hash"
            ;;
        style*)
            echo "STYLE|$clean_subject$scope|$author|$hash"
            ;;
        refactor*)
            echo "REFACTOR|$clean_subject$scope|$author|$hash"
            ;;
        perf*)
            echo "PERFORMANCE|$clean_subject$scope|$author|$hash"
            ;;
        test*)
            echo "TESTS|$clean_subject$scope|$author|$hash"
            ;;
        build*|ci*)
            echo "BUILD|$clean_subject$scope|$author|$hash"
            ;;
        chore*)
            echo "CHORE|$clean_subject$scope|$author|$hash"
            ;;
        *)
            echo "OTHER|$subject|$author|$hash"
            ;;
    esac
}

# Function to check if commit has breaking changes
has_breaking_changes() {
    local subject=$1
    local body=$2
    
    if [[ "$subject" =~ ^[a-z]+.*!:|!: ]] || [[ "$body" =~ BREAKING[[:space:]]CHANGE: ]]; then
        return 0
    fi
    return 1
}

# Function to generate changelog section for a version
generate_version_section() {
    local version=$1
    local date=$2
    local commit_range=$3
    local is_unreleased=$4
    
    # Arrays to hold categorized commits
    declare -a breaking=()
    declare -a features=()
    declare -a bugfixes=()
    declare -a docs=()
    declare -a performance=()
    declare -a refactors=()
    declare -a tests=()
    declare -a build=()
    declare -a style=()
    declare -a chores=()
    declare -a other=()
    
    print_info "Processing commits for version $version..."
    
    # Process commits
    while IFS='|' read -r hash subject author commit_date body; do
        if [ -z "$hash" ]; then continue; fi
        
        # Check for breaking changes
        local breaking_change=""
        if has_breaking_changes "$subject" "$body"; then
            breaking_change=" ⚠️ **BREAKING CHANGE**"
        fi
        
        # Categorize commit
        local category_line=$(categorize_commit "$subject" "$hash" "$author" "$commit_date")
        IFS='|' read -r category clean_subject commit_author commit_hash <<< "$category_line"
        
        local formatted_line="- $clean_subject ([@$commit_author](https://github.com/$commit_author))$breaking_change"
        
        case $category in
            FEATURE)
                if [ -n "$breaking_change" ]; then
                    breaking+=("$formatted_line")
                else
                    features+=("$formatted_line")
                fi
                ;;
            BUGFIX)
                if [ -n "$breaking_change" ]; then
                    breaking+=("$formatted_line")
                else
                    bugfixes+=("$formatted_line")
                fi
                ;;
            DOCS) docs+=("$formatted_line") ;;
            PERFORMANCE) performance+=("$formatted_line") ;;
            REFACTOR) refactors+=("$formatted_line") ;;
            TESTS) tests+=("$formatted_line") ;;
            BUILD) build+=("$formatted_line") ;;
            STYLE) style+=("$formatted_line") ;;
            CHORE) chores+=("$formatted_line") ;;
            *) other+=("$formatted_line") ;;
        esac
    done <<< "$(git log $commit_range --pretty=format:"%H|%s|%an|%ad|%b" --date=short 2>/dev/null || echo "")"
    
    # Generate section header
    if [ "$is_unreleased" = true ]; then
        echo "## [Unreleased] - $date"
    else
        echo "## [$version] - $date"
    fi
    echo ""
    
    # Output categorized changes
    local has_content=false
    
    if [ ${#breaking[@]} -gt 0 ]; then
        echo "### 💥 Breaking Changes"
        printf '%s\n' "${breaking[@]}"
        echo ""
        has_content=true
    fi
    
    if [ ${#features[@]} -gt 0 ]; then
        echo "### ✨ Features"
        printf '%s\n' "${features[@]}"
        echo ""
        has_content=true
    fi
    
    if [ ${#bugfixes[@]} -gt 0 ]; then
        echo "### 🐛 Bug Fixes"
        printf '%s\n' "${bugfixes[@]}"
        echo ""
        has_content=true
    fi
    
    if [ ${#performance[@]} -gt 0 ]; then
        echo "### ⚡ Performance Improvements"
        printf '%s\n' "${performance[@]}"
        echo ""
        has_content=true
    fi
    
    if [ ${#refactors[@]} -gt 0 ]; then
        echo "### ♻️  Code Refactoring"
        printf '%s\n' "${refactors[@]}"
        echo ""
        has_content=true
    fi
    
    if [ ${#docs[@]} -gt 0 ]; then
        echo "### 📚 Documentation"
        printf '%s\n' "${docs[@]}"
        echo ""
        has_content=true
    fi
    
    if [ ${#tests[@]} -gt 0 ]; then
        echo "### 🧪 Tests"
        printf '%s\n' "${tests[@]}"
        echo ""
        has_content=true
    fi
    
    if [ ${#build[@]} -gt 0 ]; then
        echo "### 🏗️  Build System & CI/CD"
        printf '%s\n' "${build[@]}"
        echo ""
        has_content=true
    fi
    
    if [ ${#style[@]} -gt 0 ]; then
        echo "### 💄 Styles"
        printf '%s\n' "${style[@]}"
        echo ""
        has_content=true
    fi
    
    if [ ${#chores[@]} -gt 0 ]; then
        echo "### 🔧 Chores"
        printf '%s\n' "${chores[@]}"
        echo ""
        has_content=true
    fi
    
    if [ ${#other[@]} -gt 0 ]; then
        echo "### 📝 Other Changes"
        printf '%s\n' "${other[@]}"
        echo ""
        has_content=true
    fi
    
    if [ "$has_content" = false ]; then
        echo "*No changes documented for this version.*"
        echo ""
    fi
}

# Main function
main() {
    local unreleased_only=false
    local help=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unreleased-only)
                unreleased_only=true
                shift
                ;;
            -h|--help)
                help=true
                shift
                ;;
            *)
                OUTPUT_FILE="$REPO_ROOT/$1"
                shift
                ;;
        esac
    done
    
    if [ "$help" = true ]; then
        echo "Usage: $0 [OPTIONS] [output_file]"
        echo ""
        echo "Generates changelog from git commits using conventional commit standards"
        echo ""
        echo "Arguments:"
        echo "  output_file      Output changelog file (default: CHANGELOG.md)"
        echo ""
        echo "Options:"
        echo "  --unreleased-only  Only generate unreleased changes"
        echo "  -h, --help         Show this help message"
        echo ""
        echo "Supported commit types:"
        echo "  feat:     New features (✨ Features)"
        echo "  fix:      Bug fixes (🐛 Bug Fixes)" 
        echo "  docs:     Documentation (📚 Documentation)"
        echo "  style:    Code style changes (💄 Styles)"
        echo "  refactor: Code refactoring (♻️  Code Refactoring)"
        echo "  perf:     Performance improvements (⚡ Performance Improvements)"
        echo "  test:     Tests (🧪 Tests)"
        echo "  build:    Build system/CI changes (🏗️  Build System & CI/CD)"
        echo "  chore:    Other changes (🔧 Chores)"
        exit 0
    fi
    
    local current_version=$(get_current_version)
    print_info "Current version: $current_version"
    
    # Create changelog header
    {
        echo "# Changelog"
        echo ""
        echo "All notable changes to this project will be documented in this file."
        echo ""
        echo "The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),"
        echo "and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)."
        echo ""
        echo "**Current Version**: $current_version-SNAPSHOT"
        echo ""
    } > "$OUTPUT_FILE"
    
    if [ "$unreleased_only" = true ]; then
        # Generate only unreleased changes
        local last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
        local commit_range="HEAD"
        if [ -n "$last_tag" ]; then
            commit_range="$last_tag..HEAD"
        fi
        
        local today=$(date '+%Y-%m-%d')
        generate_version_section "Unreleased" "$today" "$commit_range" true >> "$OUTPUT_FILE"
        
    else
        # Generate full changelog
        local tags=($(git tag --sort=-version:refname 2>/dev/null || git tag --sort=-creatordate 2>/dev/null || echo ""))
        
        # Add unreleased changes first
        local last_tag=""
        if [ ${#tags[@]} -gt 0 ]; then
            last_tag=${tags[0]}
        fi
        
        local unreleased_range="HEAD"
        if [ -n "$last_tag" ]; then
            unreleased_range="$last_tag..HEAD"
        fi
        
        # Check if there are unreleased changes
        local unreleased_commits=$(git log $unreleased_range --oneline 2>/dev/null | wc -l || echo "0")
        if [ "$unreleased_commits" -gt 0 ]; then
            local today=$(date '+%Y-%m-%d')
            generate_version_section "Unreleased" "$today" "$unreleased_range" true >> "$OUTPUT_FILE"
        fi
        
        # Process each tag
        local prev_tag=""
        for tag in "${tags[@]}"; do
            local tag_date=$(git log -1 --format="%ad" --date=short "$tag" 2>/dev/null || date '+%Y-%m-%d')
            local range
            
            if [ -z "$prev_tag" ]; then
                range="$tag"
            else
                range="$tag..$prev_tag"
            fi
            
            generate_version_section "$tag" "$tag_date" "$range" false >> "$OUTPUT_FILE"
            prev_tag=$tag
        done
        
        # If no tags exist, show all history as unreleased
        if [ ${#tags[@]} -eq 0 ]; then
            local today=$(date '+%Y-%m-%d')
            generate_version_section "Unreleased" "$today" "HEAD" true >> "$OUTPUT_FILE"
        fi
    fi
    
    print_info "Changelog generated: $OUTPUT_FILE"
    
    # Show summary
    echo ""
    echo -e "${BLUE}📊 Changelog Summary:${NC}"
    local total_lines=$(wc -l < "$OUTPUT_FILE")
    local version_count=$(grep -c "^## \[" "$OUTPUT_FILE" || echo "0")
    echo "  📄 Total lines: $total_lines"
    echo "  🏷️  Versions documented: $version_count"
    echo "  📁 Output file: $OUTPUT_FILE"
}

main "$@"
