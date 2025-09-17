# Country Code API

This is a Spring Boot application that provides a RESTful API to retrieve mobile country codes based on country names.

## 🚀 Automated Versioning System

This project includes a complete **npm-style automated versioning and changelog system**!

### Quick Start

```bash
# Make changes and commit using conventional format
git add .
git commit -m "feat(api): add new country lookup endpoint"

# Preview release
./scripts/automate-release.sh --dry-run

# Execute release
./scripts/automate-release.sh --push
```

📖 **[Read the Complete Automation Guide](AUTOMATION_GUIDE.md)** for detailed instructions on:

- Conventional commit message format
- Automated version bumping (semantic versioning)
- Changelog generation
- Release workflows
- CI/CD integration

## Features

- Accepts a country name as input
- Returns the corresponding mobile country code
- Exception handling for country names not found
- **Automated versioning and changelog generation**
- **Semantic release workflow**

## API Endpoints

### Get Country Code

```http
GET /api/country-code?countryName={countryName}
```

**Example:**

```bash
curl "http://localhost:8080/api/country-code?countryName=India"
```

**Response:**

```json
{
  "countryName": "India",
  "countryCode": "+91"
}
```

## Project Structure

```
country-code-api
├── src/
│   ├── main/java/com/example/countrycodeapi/
│   │   ├── CountryCodeApiApplication.java
│   │   ├── controller/CountryCodeController.java
│   │   ├── service/CountryCodeService.java
│   │   ├── exception/
│   │   │   ├── CountryNotFoundException.java
│   │   │   └── GlobalExceptionHandler.java
│   │   └── model/CountryCodeResponse.java
│   └── test/java/com/example/countrycodeapi/
├── scripts/                          # 🆕 Automation scripts
│   ├── automate-release.sh           # Main automation workflow
│   ├── semantic-version.sh           # Version analysis
│   ├── generate-changelog.sh         # Changelog generation
│   ├── update-pom-version.sh         # POM version updater
│   └── README.md                     # Script documentation
├── pom.xml                           # Enhanced with automation plugins
├── CHANGELOG.md                      # Auto-generated changelog
├── AUTOMATION_GUIDE.md              # 📖 Complete automation guide
└── README.md
```

## Setup Instructions

### 1. Clone the repository

```bash
git clone <repository-url>
cd country-code-api
```

### 2. Make scripts executable

```bash
chmod +x scripts/*.sh
```

### 3. Build the project

```bash
mvn clean install
```

### 4. Run the application

```bash
mvn spring-boot:run
```

### 5. Access the API

The API will be available at: `http://localhost:8080/api/country-code?countryName={countryName}`

## Development Workflow

### Using Conventional Commits

```bash
# Adding features (minor version bump)
git commit -m "feat: add country population data"
git commit -m "feat(api): support multiple response formats"

# Bug fixes (patch version bump)
git commit -m "fix: handle invalid country codes"
git commit -m "fix(service): resolve timeout issues"

# Breaking changes (major version bump)
git commit -m "feat!: change API response structure"
```

### Release Process

```bash
# 1. Check what version bump would happen
./scripts/semantic-version.sh --dry-run

# 2. Preview full release
./scripts/automate-release.sh --dry-run

# 3. Execute release
./scripts/automate-release.sh --push --github-release
```

## Available Maven Profiles

### Development Profile (default)

```bash
mvn compile  # Automatically generates unreleased changelog
```

### Release Profile

```bash
mvn clean package -Prelease  # Full changelog generation and semantic analysis
```

## Exception Handling

The application includes global exception handling:

- **CountryNotFoundException**: When a country name is not found
- **Global Error Handler**: Provides meaningful error responses
- **Validation**: Input parameter validation

## Supported Countries

Currently supported countries include:

- India (+91)
- United States (+1)
- United Kingdom (+44)
- Germany (+49)
- France (+33)
- And more...

## Contributing

1. **Follow conventional commit format** (see [AUTOMATION_GUIDE.md](AUTOMATION_GUIDE.md))
2. **Test your changes** locally before committing
3. **Use the automation system** for releases
4. **Update documentation** when adding new features

### Commit Message Format

```
<type>[optional scope]: <description>

Examples:
feat(api): add new endpoint
fix(service): resolve timeout
docs: update README
```

## Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history and changes.

## Scripts & Automation

| Script                          | Purpose                     |
| ------------------------------- | --------------------------- |
| `scripts/automate-release.sh`   | Complete release automation |
| `scripts/semantic-version.sh`   | Version bump analysis       |
| `scripts/generate-changelog.sh` | Changelog generation        |
| `scripts/update-pom-version.sh` | POM version management      |

## License

This project is licensed under the MIT License.

---

**🚀 Ready to automate your releases?** Check out the [AUTOMATION_GUIDE.md](AUTOMATION_GUIDE.md) to get started!
