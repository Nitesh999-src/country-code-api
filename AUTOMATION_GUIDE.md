# 🚀 Automated Versioning & Release Guide

This guide explains how to use the automated versioning system for your Spring Boot project.

## 📋 Table of Contents

- [🎯 Quick Start](#-quick-start)
- [📝 Commit Message Format](#-commit-message-format)
- [🔧 Available Commands](#-available-commands)
- [🚀 Release Workflow](#-release-workflow)
- [📖 Examples](#-examples)
- [🛠️ Troubleshooting](#️-troubleshooting)

---

## 🎯 Quick Start

### 1. Make Changes and Commit Using Conventional Format

```bash
# Example: Adding a new feature
git add .
git commit -m "feat(service): add country population data"
```

### 2. Preview What Would Happen

```bash
./scripts/automate-release.sh --dry-run
```

### 3. Execute the Release

```bash
# Local release (no push)
./scripts/automate-release.sh

# Release and push to remote
./scripts/automate-release.sh --push

# Full release with GitHub release
./scripts/automate-release.sh --push --github-release
```

---

## 📝 Commit Message Format

### Standard Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Commit Types & Version Impact

| Commit Type                    | Version Bump              | Example                      |
| ------------------------------ | ------------------------- | ---------------------------- |
| `feat:`                        | **Minor** (1.0.0 → 1.1.0) | `feat: add new endpoint`     |
| `fix:`                         | **Patch** (1.0.0 → 1.0.1) | `fix: resolve null pointer`  |
| `feat!:` or `BREAKING CHANGE:` | **Major** (1.0.0 → 2.0.0) | `feat!: change API format`   |
| `docs:`                        | **None**                  | `docs: update README`        |
| `style:`                       | **None**                  | `style: fix formatting`      |
| `refactor:`                    | **None**                  | `refactor: extract method`   |
| `test:`                        | **None**                  | `test: add unit tests`       |
| `chore:`                       | **None**                  | `chore: update dependencies` |
| `ci:`                          | **None**                  | `ci: add GitHub Actions`     |
| `build:`                       | **None**                  | `build: update Maven config` |

### ✅ Good Commit Examples

```bash
# Features (Minor version bump)
git commit -m "feat: add country code validation endpoint"
git commit -m "feat(api): support multiple response formats"
git commit -m "feat(service): implement Redis caching"
git commit -m "feat(model): add country calling codes"

# Bug Fixes (Patch version bump)
git commit -m "fix: handle null country codes gracefully"
git commit -m "fix(controller): validate input parameters"
git commit -m "fix(service): resolve timeout issues"
git commit -m "fix(exception): improve error messages"

# Breaking Changes (Major version bump)
git commit -m "feat!: change response structure to include metadata"
git commit -m "fix!: remove deprecated endpoints"

# Alternative breaking change format
git commit -m "feat: redesign country API endpoints

BREAKING CHANGE: The response format has changed from array to object structure"

# No Version Bump
git commit -m "docs: add OpenAPI documentation"
git commit -m "test: increase test coverage"
git commit -m "refactor: simplify country lookup logic"
git commit -m "chore: update Spring Boot to 3.2.6"
git commit -m "style: format code according to standards"
```

### ❌ Avoid These Patterns

```bash
# ❌ Wrong format
git commit -m "added new feature"           # Missing type and colon
git commit -m "feature: add new endpoint"   # Wrong type name
git commit -m "feat add endpoint"           # Missing colon
git commit -m "Feat: add endpoint"          # Capitalized type
git commit -m "feat: "                      # Empty description

# ❌ Wrong classification
git commit -m "fix: add new search feature"     # Should be 'feat:'
git commit -m "feat: resolve null pointer"      # Should be 'fix:'
git commit -m "feat: update documentation"      # Should be 'docs:'
```

---

## 🔧 Available Commands

### 🎯 Main Automation Script

```bash
# Full automated release workflow
./scripts/automate-release.sh [OPTIONS]
```

**Options:**

- `--dry-run` - Preview changes without making them
- `--force-version 1.2.3` - Set specific version
- `--skip-tests` - Skip running tests
- `--skip-build` - Skip building project
- `--push` - Push changes to remote repository
- `--github-release` - Create GitHub release
- `--non-interactive` - Run without prompts (for CI/CD)
- `-h, --help` - Show help

### 📊 Individual Scripts

#### Semantic Version Analysis

```bash
./scripts/semantic-version.sh [OPTIONS]

# Options:
--dry-run           # Show what version bump would happen
--force-major       # Force major version bump
--force-minor       # Force minor version bump
--force-patch       # Force patch version bump
```

#### Changelog Generation

```bash
./scripts/generate-changelog.sh [OPTIONS] [output_file]

# Options:
--unreleased-only   # Generate only unreleased changes
```

#### POM Version Update

```bash
./scripts/update-pom-version.sh [OPTIONS]

# Options:
--version 1.2.3     # Set specific version
--bump-major        # Increment major version
--bump-minor        # Increment minor version
--bump-patch        # Increment patch version
--no-snapshot       # Don't add -SNAPSHOT suffix
--dry-run           # Preview changes
```

---

## 🚀 Release Workflow

### 🧪 Development Workflow

```bash
# 1. Make your changes
# Edit files as needed

# 2. Stage changes
git add .

# 3. Commit with conventional format
git commit -m "feat(api): add country currency endpoint"

# 4. Check what version bump would happen
./scripts/semantic-version.sh --dry-run

# 5. Preview full release
./scripts/automate-release.sh --dry-run

# 6. Execute release when ready
./scripts/automate-release.sh
```

### 🚢 Production Release

```bash
# Full production release workflow
./scripts/automate-release.sh --push --github-release

# This will:
# ✅ Analyze commits for version bump
# ✅ Update pom.xml version
# ✅ Generate updated changelog
# ✅ Run tests (mvn clean test)
# ✅ Build project (mvn clean package -Prelease)
# ✅ Commit changes
# ✅ Create git tag
# ✅ Push to remote repository
# ✅ Create GitHub release
```

### 🚨 Hotfix Release

For urgent fixes that need quick deployment:

```bash
# Make urgent fix
git add .
git commit -m "fix: resolve critical security vulnerability"

# Quick release without full test/build cycle
./scripts/automate-release.sh --skip-tests --skip-build --push
```

### 🎯 Manual Version Override

For marketing releases or specific version requirements:

```bash
# Force specific version (e.g., 2.0.0 for marketing)
./scripts/automate-release.sh --force-version 2.0.0 --push
```

---

## 📖 Examples

### Example 1: Adding a New Feature

```bash
# 1. Implement new country search endpoint
# ... make code changes ...

# 2. Commit with proper format
git add .
git commit -m "feat(api): add country search by region endpoint"

# 3. Check version impact
./scripts/semantic-version.sh --dry-run
# Output: Current: 1.2.0 → New: 1.3.0 (minor bump)

# 4. Release
./scripts/automate-release.sh --push
```

### Example 2: Bug Fix

```bash
# 1. Fix validation issue
# ... make code changes ...

# 2. Commit
git add .
git commit -m "fix(controller): validate country code format properly"

# 3. Quick release
./scripts/automate-release.sh --push
# Output: 1.3.0 → 1.3.1 (patch bump)
```

### Example 3: Breaking Change

```bash
# 1. Change API response structure
# ... make code changes ...

# 2. Commit with breaking change marker
git add .
git commit -m "feat!: restructure API response to include country metadata

BREAKING CHANGE: Response format changed from simple string to object with name, code, and region fields"

# 3. Release (major version bump)
./scripts/automate-release.sh --push
# Output: 1.3.1 → 2.0.0 (major bump)
```

### Example 4: Multiple Commits

```bash
# Scenario: Multiple changes for next release

# 1. Add caching
git commit -m "feat(service): implement Redis caching for country data"

# 2. Fix bug
git commit -m "fix(api): handle case-insensitive country codes"

# 3. Add tests
git commit -m "test: add comprehensive unit tests for country service"

# 4. Update docs
git commit -m "docs: add API documentation with examples"

# 5. Check cumulative impact
./scripts/semantic-version.sh --dry-run
# Output: 2.0.0 → 2.1.0 (minor bump, because feat > fix > test > docs)

# 6. Release all changes together
./scripts/automate-release.sh --push
```

---

## 🛠️ Troubleshooting

### Common Issues

#### ❌ "Not in a git repository"

**Solution:** Make sure you're in the project root directory:

```bash
cd /path/to/your/country-code-api
./scripts/automate-release.sh --dry-run
```

#### ❌ "Script permission denied"

**Solution:** Make scripts executable:

```bash
chmod +x scripts/*.sh
```

#### ❌ "No version bump needed"

**Solution:** Check your commit messages follow conventional format:

```bash
# ❌ Wrong
git commit -m "added new feature"

# ✅ Correct
git commit -m "feat: add new feature"
```

#### ❌ "Could not extract version from pom.xml"

**Solution:** Ensure your pom.xml has a proper version element:

```xml
<project>
    <groupId>com.example</groupId>
    <artifactId>country-code-api</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <!-- ... -->
</project>
```

#### ❌ "Working directory has uncommitted changes"

**Solutions:**

```bash
# Option 1: Commit changes
git add .
git commit -m "feat: your changes"

# Option 2: Stash changes temporarily
git stash
./scripts/automate-release.sh --push
git stash pop

# Option 3: Force continue (not recommended)
# The script will ask for confirmation
```

#### ❌ "Tests failed"

**Solution:** Fix failing tests before release:

```bash
# Run tests manually to see failures
mvn clean test

# Fix issues, then:
git add .
git commit -m "fix: resolve test failures"
./scripts/automate-release.sh --push
```

### Debug Mode

For detailed execution logs:

```bash
# Debug any script
bash -x scripts/automate-release.sh --dry-run
bash -x scripts/semantic-version.sh --dry-run
```

---

## 🎨 Maven Integration

### Available Maven Commands

```bash
# Development build (auto-generates unreleased changelog)
mvn compile

# Release build (full changelog + semantic analysis)
mvn clean package -Prelease

# Version management
mvn versions:display-dependency-updates  # Check for updates
mvn versions:set -DnewVersion=1.2.3     # Set specific version
mvn versions:revert                      # Undo version change

# Manual changelog generation
mvn git-changelog:git-changelog
```

### CI/CD Integration

For automated CI/CD pipelines:

```bash
# In your CI/CD script
./scripts/automate-release.sh --non-interactive --push --github-release
```

---

## 🔗 Quick Reference

### Commit Cheat Sheet

```bash
feat: ✨ new feature      → minor bump (1.0.0 → 1.1.0)
fix: 🐛 bug fix           → patch bump (1.0.0 → 1.0.1)
feat!: 💥 breaking change → major bump (1.0.0 → 2.0.0)
docs: 📚 documentation    → no bump
test: 🧪 tests           → no bump
chore: 🔧 maintenance     → no bump
```

### Common Commands

```bash
# Preview release
./scripts/automate-release.sh --dry-run

# Local release
./scripts/automate-release.sh

# Production release
./scripts/automate-release.sh --push --github-release

# Check version impact
./scripts/semantic-version.sh --dry-run

# Generate changelog only
./scripts/generate-changelog.sh
```

---

## 🎯 Best Practices

1. **Always run `--dry-run` first** to preview changes
2. **Use descriptive commit messages** with proper scopes
3. **Group related changes** in logical commits
4. **Test locally** before pushing to production
5. **Review generated changelog** before finalizing release
6. **Keep breaking changes documented** in commit body
7. **Use scopes consistently** (api, service, model, config, etc.)

---

## 🏆 Success!

You now have a complete npm-style automated versioning system for your Spring Boot project. Your workflow is:

1. **Code** → 2. **Commit** (conventional format) → 3. **Release** (automated) → 4. **Deploy** ✨

Happy coding! 🚀

---

_Generated by the Country Code API Automation System_
