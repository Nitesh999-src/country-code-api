package com.example.countrycodeapi.exception;

public class CountryNotFoundException extends RuntimeException {
    public CountryNotFoundException(String countryName) {
        super("Country not found: " + countryName);
    }
    
    // Added overloaded constructor for better error handling
    public CountryNotFoundException(String countryName, Throwable cause) {
        super("Country not found: " + countryName, cause);
    }
}