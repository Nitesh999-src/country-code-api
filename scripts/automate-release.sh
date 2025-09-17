#!/usr/bin/env bash

# Automated Release Script - NPM-style semantic release for Maven projects
# Orchestrates semantic versioning, changelog generation, and release automation
# Usage: ./scripts/automate-release.sh [OPTIONS]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
print_success() { echo -e "${PURPLE}[SUCCESS]${NC} $1"; }

REPO_ROOT=$(git rev-parse --show-toplevel)
SCRIPTS_DIR="$REPO_ROOT/scripts"

# Default values
DRY_RUN=false
SKIP_TESTS=false
SKIP_BUILD=false
FORCE_VERSION=""
PUSH_TO_REMOTE=false
CREATE_GITHUB_RELEASE=false
INTERACTIVE=true
MAVEN_PROFILES="release"

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check required tools
    if ! command -v git > /dev/null 2>&1; then
        missing_tools+=("git")
    fi
    
    if ! command -v mvn > /dev/null 2>&1; then
        missing_tools+=("maven")
    fi
    
    if ! command -v java > /dev/null 2>&1; then
        missing_tools+=("java")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository!"
        return 1
    fi
    
    # Check if working directory is clean (unless dry run)
    if [ "$DRY_RUN" = false ]; then
        local status=$(git status --porcelain)
        if [ -n "$status" ]; then
            print_warn "Working directory has uncommitted changes:"
            echo "$status"
            if [ "$INTERACTIVE" = true ]; then
                echo -n "Continue anyway? (y/N): "
                read -r response
                if [[ ! "$response" =~ ^[Yy]$ ]]; then
                    print_error "Please commit or stash changes before running release"
                    return 1
                fi
            else
                print_error "Working directory must be clean for automated release"
                return 1
            fi
        fi
    fi
    
    # Check if scripts exist
    local required_scripts=("semantic-version.sh" "generate-changelog.sh" "update-pom-version.sh")
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$SCRIPTS_DIR/$script" ]; then
            print_error "Required script not found: $SCRIPTS_DIR/$script"
            return 1
        fi
        
        if [ ! -x "$SCRIPTS_DIR/$script" ]; then
            print_warn "Making $script executable..."
            chmod +x "$SCRIPTS_DIR/$script"
        fi
    done
    
    print_info "Prerequisites check passed"
    return 0
}

# Function to determine version bump
analyze_version_bump() {
    print_step "Analyzing commits for version bump..."
    
    if [ -n "$FORCE_VERSION" ]; then
        echo "manual"
        return 0
    fi
    
    # Run semantic analysis and capture bump type from stderr
    local bump_output=$("$SCRIPTS_DIR/semantic-version.sh" --dry-run 2>&1)
    
    if echo "$bump_output" | grep -q "Determined bump type: minor\|Determined bump type: major\|Determined bump type: patch"; then
        echo "auto"
    else
        echo "none"
    fi
}

# Function to update version
update_project_version() {
    local bump_type=$1
    local new_version=$2
    
    print_step "Updating project version..."
    
    if [ "$bump_type" = "manual" ]; then
        if [ "$DRY_RUN" = true ]; then
            print_info "Would update version to: $new_version-SNAPSHOT"
        else
            "$SCRIPTS_DIR/update-pom-version.sh" --version "$new_version" >&2
        fi
        echo "$new_version"
    elif [ "$bump_type" = "auto" ]; then
        if [ "$DRY_RUN" = true ]; then
            "$SCRIPTS_DIR/semantic-version.sh" --dry-run >&2
            # Extract new version from the output 
            local new_ver=$(echo "$("$SCRIPTS_DIR/semantic-version.sh" --dry-run 2>&1)" | grep "New:" | sed 's/.*New: *\([0-9.]*\).*/\1/')
            echo "$new_ver"
        else
            new_version=$("$SCRIPTS_DIR/semantic-version.sh")
            echo "$new_version"
        fi
    else
        print_warn "No version bump needed based on commit analysis"
        return 1
    fi
}

# Function to generate changelog
generate_project_changelog() {
    print_step "Generating project changelog..."
    
    if [ "$DRY_RUN" = true ]; then
        print_info "Would generate changelog with current changes"
        "$SCRIPTS_DIR/generate-changelog.sh" --help > /dev/null
    else
        "$SCRIPTS_DIR/generate-changelog.sh"
        print_info "Changelog updated in CHANGELOG.md"
    fi
}

# Function to run tests
run_project_tests() {
    if [ "$SKIP_TESTS" = true ]; then
        print_info "Skipping tests (--skip-tests flag used)"
        return 0
    fi
    
    print_step "Running project tests..."
    
    if [ "$DRY_RUN" = true ]; then
        print_info "Would run: mvn clean test"
    else
        mvn clean test -q
        print_info "All tests passed"
    fi
}

# Function to build project
build_project() {
    if [ "$SKIP_BUILD" = true ]; then
        print_info "Skipping build (--skip-build flag used)"
        return 0
    fi
    
    print_step "Building project..."
    
    local maven_cmd="mvn clean package"
    if [ -n "$MAVEN_PROFILES" ]; then
        maven_cmd="$maven_cmd -P$MAVEN_PROFILES"
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_info "Would run: $maven_cmd"
    else
        $maven_cmd -q
        print_info "Build completed successfully"
    fi
}

# Function to create git tag
create_git_tag() {
    local version=$1
    local tag_name="v$version"
    
    print_step "Creating git tag: $tag_name"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "Would create tag: $tag_name"
        return 0
    fi
    
    # Stage and commit version and changelog changes
    git add pom.xml CHANGELOG.md
    if git diff --staged --quiet; then
        print_info "No changes to commit"
    else
        git commit -m "chore(release): prepare release $version

[skip ci]"
        print_info "Committed release preparation changes"
    fi
    
    # Create annotated tag
    git tag -a "$tag_name" -m "Release version $version

$(head -20 CHANGELOG.md | tail -n +4)"
    
    print_info "Created tag: $tag_name"
    echo "$tag_name"
}

# Function to push changes
push_changes() {
    local tag_name=$1
    
    if [ "$PUSH_TO_REMOTE" = false ]; then
        print_info "Skipping push to remote (use --push to enable)"
        return 0
    fi
    
    print_step "Pushing changes to remote..."
    
    if [ "$DRY_RUN" = true ]; then
        print_info "Would push commits and tag $tag_name to remote"
        return 0
    fi
    
    # Get current branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    # Push commits
    git push origin "$current_branch"
    print_info "Pushed commits to origin/$current_branch"
    
    # Push tag
    git push origin "$tag_name"
    print_info "Pushed tag $tag_name to remote"
}

# Function to create GitHub release (placeholder)
create_github_release() {
    local tag_name=$1
    local version=$2
    
    if [ "$CREATE_GITHUB_RELEASE" = false ]; then
        print_info "Skipping GitHub release creation (use --github-release to enable)"
        return 0
    fi
    
    print_step "Creating GitHub release..."
    
    if [ "$DRY_RUN" = true ]; then
        print_info "Would create GitHub release for $tag_name"
        return 0
    fi
    
    if command -v gh > /dev/null 2>&1; then
        # Extract changelog for this version
        local release_notes=$(awk "/^## \[$version\]/,/^## \[/{if(!/^## \[/ || /^## \[$version\]/) print}" CHANGELOG.md | head -n -1)
        
        gh release create "$tag_name" \
            --title "Release $version" \
            --notes "$release_notes" \
            --generate-notes \
            target/*.jar || print_warn "Failed to create GitHub release (check gh CLI setup)"
    else
        print_warn "GitHub CLI (gh) not found - skipping GitHub release"
        print_info "You can manually create a release at: https://github.com/your-repo/releases/new?tag=$tag_name"
    fi
}

# Function to show release summary
show_summary() {
    local version=$1
    local tag_name=$2
    local bump_type=$3
    
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                RELEASE SUMMARY               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  📦 ${BLUE}Version:${NC}     $version"
    echo -e "  🏷️  ${BLUE}Tag:${NC}         $tag_name"
    echo -e "  📈 ${BLUE}Bump Type:${NC}   $bump_type"
    echo -e "  📝 ${BLUE}Changelog:${NC}   Updated"
    echo -e "  🧪 ${BLUE}Tests:${NC}       $([ "$SKIP_TESTS" = true ] && echo "Skipped" || echo "Passed")"
    echo -e "  🏗️  ${BLUE}Build:${NC}       $([ "$SKIP_BUILD" = true ] && echo "Skipped" || echo "Completed")"
    echo -e "  🚀 ${BLUE}Push:${NC}        $([ "$PUSH_TO_REMOTE" = true ] && echo "Yes" || echo "No")"
    echo -e "  📡 ${BLUE}GitHub:${NC}      $([ "$CREATE_GITHUB_RELEASE" = true ] && echo "Yes" || echo "No")"
    echo -e "  🧪 ${BLUE}Dry Run:${NC}     $([ "$DRY_RUN" = true ] && echo "Yes" || echo "No")"
    echo ""
    
    if [ "$DRY_RUN" = false ]; then
        print_success "🎉 Release completed successfully!"
        echo ""
        echo "Next steps:"
        echo "  • Review the changelog: CHANGELOG.md"
        echo "  • Check the new tag: git tag -l"
        if [ "$PUSH_TO_REMOTE" = false ]; then
            echo "  • Push changes: git push && git push --tags"
        fi
        if [ "$CREATE_GITHUB_RELEASE" = false ]; then
            echo "  • Create GitHub release if needed"
        fi
    else
        print_info "This was a dry run - no changes were made"
    fi
}

# Function to print help
print_help() {
    cat << EOF
Automated Release Script - NPM-style semantic release for Maven projects

USAGE:
    $0 [OPTIONS]

DESCRIPTION:
    Automates the release process by analyzing commit messages, determining
    version bumps, updating changelog, running tests, building the project,
    and creating git tags. Similar to npm's semantic-release workflow.

OPTIONS:
    --dry-run                 Show what would be done without making changes
    --force-version VERSION   Force specific version (e.g., 1.2.3)
    --skip-tests             Skip running tests
    --skip-build             Skip building the project
    --push                   Push changes and tags to remote repository
    --github-release         Create GitHub release (requires gh CLI)
    --non-interactive        Run without user prompts
    --maven-profiles PROFILES Maven profiles to use (default: release)
    -h, --help               Show this help message

EXAMPLES:
    # Dry run to see what would happen
    $0 --dry-run

    # Full automated release with push
    $0 --push --github-release

    # Quick release without tests/build (for hotfixes)
    $0 --skip-tests --skip-build --push

    # Manual version override
    $0 --force-version 2.0.0 --push

WORKFLOW:
    1. Check prerequisites (git, maven, clean working directory)
    2. Analyze commits to determine version bump type
    3. Update pom.xml version
    4. Generate updated changelog
    5. Run tests (unless --skip-tests)
    6. Build project (unless --skip-build)  
    7. Commit changes and create git tag
    8. Push to remote (if --push)
    9. Create GitHub release (if --github-release)

COMMIT CONVENTIONS:
    feat:     Minor version bump (new feature)
    fix:      Patch version bump (bug fix)
    BREAKING CHANGE: Major version bump
    docs:, style:, refactor:, test:, chore: No version bump

For more information, visit: https://conventionalcommits.org/
EOF
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force-version)
                FORCE_VERSION="$2"
                shift 2
                ;;
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --push)
                PUSH_TO_REMOTE=true
                shift
                ;;
            --github-release)
                CREATE_GITHUB_RELEASE=true
                shift
                ;;
            --non-interactive)
                INTERACTIVE=false
                shift
                ;;
            --maven-profiles)
                MAVEN_PROFILES="$2"
                shift 2
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done
    
    # Show header
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          AUTOMATED RELEASE WORKFLOW         ║${NC}"
    echo -e "${CYAN}║      NPM-style semantic release for Maven   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        print_warn "🧪 DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    # Step 1: Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    # Step 2: Analyze version bump
    local bump_type=$(analyze_version_bump)
    local new_version=""
    
    if [ "$bump_type" = "none" ] && [ -z "$FORCE_VERSION" ]; then
        print_warn "No version bump needed based on commit analysis"
        print_info "Use --force-version to override, or make commits with conventional commit messages"
        exit 0
    fi
    
    # Step 3: Update version
    if [ -n "$FORCE_VERSION" ]; then
        new_version=$(update_project_version "manual" "$FORCE_VERSION")
    else
        new_version=$(update_project_version "auto" "")
    fi
    
    if [ -z "$new_version" ]; then
        print_error "Failed to determine new version"
        exit 1
    fi
    
    # Remove -SNAPSHOT suffix for display
    local display_version=$(echo "$new_version" | sed 's/-SNAPSHOT//')
    
    # Step 4: Generate changelog
    if ! generate_project_changelog; then
        print_error "Failed to generate changelog"
        exit 1
    fi
    
    # Step 5: Run tests
    if ! run_project_tests; then
        print_error "Tests failed"
        exit 1
    fi
    
    # Step 6: Build project
    if ! build_project; then
        print_error "Build failed"
        exit 1
    fi
    
    # Step 7: Create git tag
    local tag_name=""
    if [ "$DRY_RUN" = false ]; then
        tag_name=$(create_git_tag "$display_version")
    else
        tag_name="v$display_version"
    fi
    
    # Step 8: Push changes
    if ! push_changes "$tag_name"; then
        print_warn "Failed to push changes"
    fi
    
    # Step 9: Create GitHub release
    if ! create_github_release "$tag_name" "$display_version"; then
        print_warn "Failed to create GitHub release"
    fi
    
    # Step 10: Show summary
    show_summary "$display_version" "$tag_name" "$bump_type"
}

# Run main function
main "$@"
