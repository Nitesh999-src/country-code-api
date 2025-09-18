package com.example.countrycodeapi.exception;

import java.util.List;

public class InvalidCountryNameException extends RuntimeException {
    private final List<String> suggestions;
    
    public InvalidCountryNameException(String countryName, List<String> suggestions) {
        super(String.format("Invalid country name: '%s'. Did you mean one of: %s", 
            countryName, suggestions.isEmpty() ? "N/A" : String.join(", ", suggestions)));
        this.suggestions = suggestions;
    }
    
    public InvalidCountryNameException(String countryName) {
        super(String.format("Invalid country name: '%s'", countryName));
        this.suggestions = List.of();
    }
    
    public List<String> getSuggestions() {
        return suggestions;
    }
}
