# Automation Scripts

This directory contains scripts for automated versioning and changelog generation, similar to npm's semantic release workflow.

## 📦 Integration Guide - Use in Your Spring Boot Project

### 🎯 Overview

These automation scripts can be easily integrated into any Spring Boot project to provide NPM-style automated versioning, changelog generation, and releases.

### 🏗️ **Step 1: Copy Scripts Folder**

1. **Copy the entire `scripts/` folder** to your Spring Boot project root:

```
your-spring-boot-project/
├── src/
├── pom.xml
└── scripts/              ← Copy this entire folder here
    ├── automate-release.sh
    ├── generate-changelog.sh
    ├── semantic-version.sh
    └── update-pom-version.sh
```

2. **Make scripts executable:**

```bash
chmod +x scripts/*.sh
```

### 🔧 **Step 2: Update pom.xml Dependencies & Profiles**

Add the following to your `pom.xml`:

#### **Required Properties (add to `<properties>` section):**

```xml
<properties>
    <java.version>17</java.version>
    <maven.compiler.source>17</maven.compiler.source>
    <maven.compiler.target>17</maven.compiler.target>
</properties>
```

#### **Required Plugins (add to `<build><plugins>` section):**

```xml
<build>
    <plugins>
        <!-- Spring Boot Maven Plugin -->
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>

        <!-- Versions Maven Plugin - for version management -->
        <plugin>
            <groupId>org.codehaus.mojo</groupId>
            <artifactId>versions-maven-plugin</artifactId>
            <version>2.16.2</version>
            <configuration>
                <generateBackupPoms>false</generateBackupPoms>
            </configuration>
        </plugin>

        <!-- Maven Release Plugin -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-release-plugin</artifactId>
            <version>3.0.1</version>
            <configuration>
                <autoVersionSubmodules>true</autoVersionSubmodules>
                <useReleaseProfile>false</useReleaseProfile>
                <releaseProfiles>release</releaseProfiles>
                <goals>deploy</goals>
            </configuration>
        </plugin>

        <!-- Exec Maven Plugin - for running automation scripts -->
        <plugin>
            <groupId>org.codehaus.mojo</groupId>
            <artifactId>exec-maven-plugin</artifactId>
            <version>3.1.1</version>
            <configuration>
                <executable>bash</executable>
            </configuration>
        </plugin>
    </plugins>
</build>
```

#### **Required Profiles (add entire `<profiles>` section):**

> **💡 Note**: The profiles below include automatic script execution during Maven builds. If you prefer **manual-only execution**, comment out the `<executions>` sections in each profile and run scripts manually via terminal.

```xml
<profiles>
    <!-- Release Profile -->
    <profile>
        <id>release</id>
        <properties>
            <maven.test.skip>false</maven.test.skip>
            <maven.javadoc.skip>false</maven.javadoc.skip>
        </properties>
        <build>
            <plugins>
                <!-- Run semantic versioning and changelog generation -->
                <plugin>
                    <groupId>org.codehaus.mojo</groupId>
                    <artifactId>exec-maven-plugin</artifactId>
                    <executions>
                        <execution>
                            <id>semantic-version</id>
                            <phase>validate</phase>
                            <goals>
                                <goal>exec</goal>
                            </goals>
                            <configuration>
                                <arguments>
                                    <argument>scripts/semantic-version.sh</argument>
                                    <argument>--dry-run</argument>
                                </arguments>
                            </configuration>
                        </execution>
                        <execution>
                            <id>generate-full-changelog</id>
                            <phase>prepare-package</phase>
                            <goals>
                                <goal>exec</goal>
                            </goals>
                            <configuration>
                                <arguments>
                                    <argument>scripts/generate-changelog.sh</argument>
                                    <argument>CHANGELOG.md</argument>
                                </arguments>
                            </configuration>
                        </execution>
                    </executions>
                </plugin>
            </plugins>
        </build>
    </profile>

    <!-- Development Profile -->
    <profile>
        <id>dev</id>
        <activation>
            <activeByDefault>true</activeByDefault>
        </activation>
        <build>
            <plugins>
                <plugin>
                    <groupId>org.codehaus.mojo</groupId>
                    <artifactId>exec-maven-plugin</artifactId>
                    <executions>
                        <execution>
                            <id>generate-unreleased-changelog</id>
                            <phase>compile</phase>
                            <goals>
                                <goal>exec</goal>
                            </goals>
                            <configuration>
                                <arguments>
                                    <argument>scripts/generate-changelog.sh</argument>
                                    <argument>--unreleased-only</argument>
                                </arguments>
                            </configuration>
                        </execution>
                    </executions>
                </plugin>
            </plugins>
        </build>
    </profile>
</profiles>
```

#### **SCM Configuration (add to root of `<project>`):**

```xml
<scm>
    <connection>scm:git:git://github.com/yourusername/your-repo.git</connection>
    <developerConnection>scm:git:ssh://github.com:yourusername/your-repo.git</developerConnection>
    <url>http://github.com/yourusername/your-repo/tree/main</url>
</scm>
```

### ⚙️ **Step 3: Update Scripts for Your Project**

#### **🎯 Critical: Update GroupId Detection**

**The scripts are currently hardcoded for `com.example` groupId. You MUST update this:**

1. **Edit `scripts/semantic-version.sh`** - Replace line ~33:

```bash
# OLD (line 33):
local version=$(sed -n '/<groupId>com.example<\/groupId>/,/<version>/p' "$POM_PATH" | grep '<version>' | sed 's/.*<version>\(.*\)<\/version>.*/\1/' | head -1)

# NEW - Replace com.example with YOUR groupId:
local version=$(sed -n '/<groupId>YOUR_GROUP_ID<\/groupId>/,/<version>/p' "$POM_PATH" | grep '<version>' | sed 's/.*<version>\(.*\)<\/version>.*/\1/' | head -1)
```

2. **Edit `scripts/generate-changelog.sh`** - Replace line ~37:

```bash
# OLD:
local version=$(sed -n '/<groupId>com.example<\/groupId>/,/<version>/p' "$pom_path" | grep '<version>' | sed 's/.*<version>\(.*\)<\/version>.*/\1/' | head -1)

# NEW - Replace com.example with YOUR groupId:
local version=$(sed -n '/<groupId>YOUR_GROUP_ID<\/groupId>/,/<version>/p' "$pom_path" | grep '<version>' | sed 's/.*<version>\(.*\)<\/version>.*/\1/' | head -1)
```

3. **Edit `scripts/update-pom-version.sh`** - Replace line ~40:

```bash
# OLD:
local version=$(sed -n '/<groupId>com.example<\/groupId>/,/<version>/p' "$POM_PATH" | grep '<version>' | sed 's/.*<version>\(.*\)<\/version>.*/\1/' | head -1)

# NEW - Replace com.example with YOUR groupId:
local version=$(sed -n '/<groupId>YOUR_GROUP_ID<\/groupId>/,/<version>/p' "$POM_PATH" | grep '<version>' | sed 's/.*<version>\(.*\)<\/version>.*/\1/' | head -1)
```

**Example:** If your `pom.xml` has `<groupId>io.mycompany</groupId>`, then use:

```bash
local version=$(sed -n '/<groupId>io.mycompany<\/groupId>/,/<version>/p' "$POM_PATH" | grep '<version>' | sed 's/.*<version>\(.*\)<\/version>.*/\1/' | head -1)
```

### 🖥️ **Platform Compatibility**

| Platform        | Status                 | Requirements                          | Notes                   |
| --------------- | ---------------------- | ------------------------------------- | ----------------------- |
| **🐧 Linux**    | ✅ **Fully Supported** | `bash`, `git`, `maven`, `grep`, `sed` | **Best performance**    |
| **🍎 macOS**    | ✅ **Fully Supported** | `bash`, `git`, `maven`, `grep`, `sed` | **Tested platform**     |
| **🏢 Unix/BSD** | ✅ **Compatible**      | `bash`, `git`, `maven`, `grep`, `sed` | May need minor tweaks   |
| **🪟 Windows**  | ⚠️ **Requires Setup**  | WSL2 or Git Bash                      | See Windows setup below |

#### **Windows Setup Options:**

**Option 1: WSL2 (Recommended)**

```bash
# Install Ubuntu on WSL2
wsl --install
# Then run all scripts in WSL2 environment
```

**Option 2: Git Bash**

```bash
# Use Git Bash terminal
# Ensure you have Maven and Git in PATH
# Scripts should work with minor modifications
```

**Option 3: PowerShell Alternative**

- Consider using the PowerShell equivalent scripts (not included)
- Or use Docker to run in Linux container

### 🛠️ **Step 4: Initialize Your Project**

1. **Create initial git tag:**

```bash
git tag v1.0.0
git push --tags
```

2. **Test the setup:**

```bash
./scripts/automate-release.sh --dry-run
```

3. **Generate first changelog:**

```bash
./scripts/generate-changelog.sh
```

### 🎯 **Step 5: Configure GitHub Integration (Optional)**

For automated GitHub releases:

1. **Install GitHub CLI:**

```bash
# macOS
brew install gh

# Linux
sudo apt install gh
# or
sudo snap install gh
```

2. **Authenticate:**

```bash
gh auth login
```

3. **Enable in automation:**

```bash
./scripts/automate-release.sh --github-release --push
```

### ⚡ **Quick Integration Checklist**

- [ ] Copied `scripts/` folder to project root
- [ ] Made scripts executable: `chmod +x scripts/*.sh`
- [ ] Added required plugins to `pom.xml`
- [ ] Added profiles to `pom.xml`
- [ ] Updated groupId in all 3 scripts (semantic-version.sh, generate-changelog.sh, update-pom-version.sh)
- [ ] Added SCM configuration to `pom.xml`
- [ ] Created initial git tag: `git tag v1.0.0`
- [ ] Tested with: `./scripts/automate-release.sh --dry-run`

### 🚨 **Common Integration Issues**

| Issue                    | Cause                    | Solution                         |
| ------------------------ | ------------------------ | -------------------------------- |
| **Version not found**    | Wrong groupId in scripts | Update groupId in 3 script files |
| **Permission denied**    | Scripts not executable   | Run `chmod +x scripts/*.sh`      |
| **Command not found**    | Missing dependencies     | Install `git`, `maven`, `bash`   |
| **Windows line endings** | CRLF vs LF               | Run `dos2unix scripts/*.sh`      |

### 🎉 **You're Ready!**

After completing these steps, your Spring Boot project will have:

- ✅ **NPM-style semantic versioning**
- ✅ **Automated changelog generation**
- ✅ **Integrated Maven workflows**
- ✅ **GitHub release automation**
- ✅ **Cross-platform compatibility**

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
