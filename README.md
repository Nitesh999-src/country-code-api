=======
# Country Code API

This is a Spring Boot application that provides a RESTful API to retrieve mobile country codes based on country names.

## Features

- Accepts a country name as input.
- Returns the corresponding mobile country code.
- Exception handling for country names not found.

## Project Structure

```
country-code-api
├── src
│   ├── main
│   │   ├── java
│   │   │   └── com
│   │   │       └── example
│   │   │           └── countrycodeapi
│   │   │               ├── CountryCodeApiApplication.java
│   │   │               ├── controller
│   │   │               │   └── CountryCodeController.java
│   │   │               ├── service
│   │   │               │   └── CountryCodeService.java
│   │   │               ├── exception
│   │   │               │   ├── CountryNotFoundException.java
│   │   │               │   └── GlobalExceptionHandler.java
│   │   │               └── model
│   │   │                   └── CountryCodeResponse.java
│   │   └── resources
│   │       └── application.properties
│   └── test
│       └── java
│           └── com
│               └── example
│                   └── countrycodeapi
│                       └── CountryCodeApiApplicationTests.java
├── .gitignore
├── pom.xml
└── README.md
```

## Setup Instructions

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd country-code-api
   ```

2. **Build the project:**
   Make sure you have Maven installed. Run the following command to build the project:
   ```bash
   mvn clean install
   ```

3. **Run the application:**
   You can run the application using the following command:
   ```bash
   mvn spring-boot:run
   ```

4. **Access the API:**
   Once the application is running, you can access the API at:
   ```
   http://localhost:8080/api/country-code?countryName={countryName}
   ```

## Exception Handling

The application includes global exception handling for cases where a country name is not found. A `CountryNotFoundException` will be thrown, and a meaningful error message will be returned.

## License

This project is licensed under the MIT License.
>>>>>>> e20667e (simple api for getting country code)
