# Automation Scripts

This directory contains scripts for automated versioning and changelog generation, similar to npm's semantic release workflow.

## 🚀 Quick Start

### Automated Release (Recommended)

```bash
# Dry run to see what would happen
./scripts/automate-release.sh --dry-run

# Full automated release
./scripts/automate-release.sh --push --github-release

# Quick release for hotfixes
./scripts/automate-release.sh --skip-tests --skip-build --push
```

### Manual Usage

```bash
# Update version based on commits
./scripts/semantic-version.sh

# Generate changelog
./scripts/generate-changelog.sh

# Update pom.xml version manually
./scripts/update-pom-version.sh --bump-minor
```

## 📦 Scripts Overview

### `automate-release.sh` - Master Automation Script

The main script that orchestrates the entire release workflow:

- ✅ Analyzes commits for version bumps
- ✅ Updates pom.xml version
- ✅ Generates changelog
- ✅ Runs tests and builds project
- ✅ Creates git tags
- ✅ Pushes to remote (optional)
- ✅ Creates GitHub releases (optional)

**Usage:**

```bash
./scripts/automate-release.sh [OPTIONS]

Options:
  --dry-run                 Show what would be done without making changes
  --force-version VERSION   Force specific version (e.g., 1.2.3)
  --skip-tests             Skip running tests
  --skip-build             Skip building the project
  --push                   Push changes and tags to remote repository
  --github-release         Create GitHub release (requires gh CLI)
  --non-interactive        Run without user prompts
  --maven-profiles PROFILES Maven profiles to use (default: release)
  -h, --help               Show help message
```

### `semantic-version.sh` - Version Analysis

Analyzes git commits to determine appropriate version bump using conventional commit standards.

**Commit Types:**

- `feat:` → Minor version bump (1.0.0 → 1.1.0)
- `fix:` → Patch version bump (1.0.0 → 1.0.1)
- `BREAKING CHANGE:` or `!` → Major version bump (1.0.0 → 2.0.0)
- `docs:`, `style:`, `refactor:`, `test:`, `chore:` → No version bump

**Usage:**

```bash
./scripts/semantic-version.sh [OPTIONS]

Options:
  --force-major    Force a major version bump
  --force-minor    Force a minor version bump
  --force-patch    Force a patch version bump
  --dry-run        Show what would be done without making changes
  -h, --help       Show help message
```

### `generate-changelog.sh` - Changelog Generation

Generates a beautiful, categorized changelog from git commits using conventional commit standards.

**Features:**

- 📝 Categorizes commits by type (Features, Bug Fixes, etc.)
- 🎨 Emoji icons for better readability
- 🏷️ Groups changes by version/tag
- 🔗 GitHub-style author links
- ⚠️ Highlights breaking changes

**Usage:**

```bash
./scripts/generate-changelog.sh [OPTIONS] [output_file]

Options:
  --unreleased-only    Only generate unreleased changes
  -h, --help           Show help message

Arguments:
  output_file          Output changelog file (default: CHANGELOG.md)
```

### `update-pom-version.sh` - POM Version Updater

Updates the version in pom.xml with proper validation and backup.

**Features:**

- ✅ Validates semantic version format
- 📦 Automatically adds -SNAPSHOT suffix
- 💾 Creates backups before changes
- 🔍 Verifies updates were successful

**Usage:**

```bash
./scripts/update-pom-version.sh [OPTIONS]

Options:
  --version VERSION    Set specific version
  --bump-major         Increment major version
  --bump-minor         Increment minor version
  --bump-patch         Increment patch version
  --no-snapshot        Don't append -SNAPSHOT to version
  --dry-run            Show what would be done without making changes
  -h, --help           Show help message
```

## 🔧 Maven Integration

The project is configured with Maven profiles for automated builds:

### Development Profile (default)

```bash
mvn compile  # Generates unreleased changelog automatically
```

### Release Profile

```bash
mvn clean package -Prelease  # Full changelog generation and semantic analysis
```

### Available Maven Goals

**Version Management:**

```bash
# Check for version updates
mvn versions:display-dependency-updates

# Update version in pom.xml
mvn versions:set -DnewVersion=1.2.3

# Revert version changes
mvn versions:revert
```

**Release Process:**

```bash
# Prepare release (updates versions, creates tag)
mvn release:prepare

# Perform release (builds and deploys)
mvn release:perform

# Clean up after failed release
mvn release:clean
```

**Changelog Generation:**

```bash
# Generate changelog using git-changelog-maven-plugin
mvn git-changelog:git-changelog
```

## 📋 Conventional Commits

This project follows [Conventional Commits](https://conventionalcommits.org/) specification:

### Commit Message Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Examples

```bash
# Feature (minor version bump)
feat: add country code validation API
feat(api): support multiple response formats

# Bug fix (patch version bump)
fix: handle null country codes gracefully
fix(controller): return proper HTTP status codes

# Breaking change (major version bump)
feat!: change API response format
feat: remove deprecated endpoints

BREAKING CHANGE: The response format has changed
```

### Commit Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation only changes
- **style**: Changes that don't affect code meaning (formatting, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **build**: Changes affecting build system or dependencies
- **ci**: Changes to CI configuration files and scripts
- **chore**: Other changes that don't modify source or test files

## 🎯 Workflow Examples

### Regular Development

```bash
# Make changes and commit using conventional commits
git add .
git commit -m "feat: add new country lookup endpoint"

# Before release, run automated workflow
./scripts/automate-release.sh --dry-run  # Preview changes
./scripts/automate-release.sh --push     # Execute release
```

### Hotfix Release

```bash
# Make urgent fix and commit
git add .
git commit -m "fix: resolve critical security vulnerability"

# Quick release without full build/test cycle
./scripts/automate-release.sh --skip-tests --skip-build --push
```

### Manual Version Override

```bash
# Force specific version (e.g., for marketing reasons)
./scripts/automate-release.sh --force-version 2.0.0 --push
```

### CI/CD Integration

```bash
# In your CI/CD pipeline
./scripts/automate-release.sh --non-interactive --push --github-release
```

## 🛠️ Prerequisites

- **Git**: Version control
- **Maven**: Build tool (3.6+ recommended)
- **Java**: JDK 17+ (for Spring Boot 3.x)
- **GitHub CLI** (optional): For GitHub release creation (`gh`)

## 🚨 Troubleshooting

### Common Issues

**1. Script Permission Denied**

```bash
chmod +x scripts/*.sh
```

**2. xmllint not found**
The scripts will fallback to sed/awk if xmllint is unavailable, but installing it improves reliability:

```bash
# macOS
brew install libxml2

# Ubuntu/Debian
sudo apt-get install libxml2-utils
```

**3. Version Extraction Failed**
Ensure your pom.xml has a proper version element:

```xml
<project>
    <groupId>com.example</groupId>
    <artifactId>your-project</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <!-- ... -->
</project>
```

**4. No Version Bump Detected**
Make sure your commits follow conventional commit format:

```bash
# ❌ Wrong
git commit -m "added new feature"

# ✅ Correct
git commit -m "feat: add new feature"
```

### Debug Mode

Add `-x` to any script for detailed execution logs:

```bash
bash -x scripts/automate-release.sh --dry-run
```

## 🤝 Contributing

1. Follow conventional commit messages
2. Test scripts with `--dry-run` first
3. Update documentation for new features
4. Verify all scripts are executable

## 📄 License

These scripts are part of the country-code-api project and follow the same license terms.
