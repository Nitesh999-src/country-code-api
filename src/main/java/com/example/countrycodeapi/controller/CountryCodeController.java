package com.example.countrycodeapi.controller;

import com.example.countrycodeapi.exception.CountryNotFoundException;
import com.example.countrycodeapi.exception.InvalidCountryNameException;
import com.example.countrycodeapi.model.CountryCodeResponse;
import com.example.countrycodeapi.service.CountryCodeService;
import com.example.countrycodeapi.service.CountryValidationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;
import java.util.List;
import java.util.Set;

@RestController
public class CountryCodeController {

    private final CountryCodeService countryCodeService;
    private final CountryValidationService countryValidationService;

    @Autowired
    public CountryCodeController(CountryCodeService countryCodeService, 
                               CountryValidationService countryValidationService) {
        this.countryCodeService = countryCodeService;
        this.countryValidationService = countryValidationService;
    }

    @GetMapping("/country-code/{countryName}")
    public ResponseEntity<CountryCodeResponse> getCountryCode(@PathVariable String countryName) {
        // First validate the country name
        if (!countryValidationService.isValidCountry(countryName)) {
            List<String> suggestions = countryValidationService.getSuggestions(countryName);
            throw new InvalidCountryNameException(countryName, suggestions);
        }
        
        String countryCode = countryCodeService.getCountryCode(countryName);
        if (countryCode == null) {
            throw new CountryNotFoundException("Country not found: " + countryName);
        }
        // Determine region based on country name (simplified logic)
        String region = determineRegion(countryName);
        return ResponseEntity.ok(new CountryCodeResponse(countryName, countryCode, region));
    }
    
    private String determineRegion(String countryName) {
        switch (countryName.toLowerCase()) {
            case "india":
            case "china":
                return "Asia";
            case "united states":
            case "canada":
            case "mexico":
            case "brazil":
            case "argentina":
                return "Americas";
            case "united kingdom":
            case "france":
            case "germany":
            case "italy":
                return "Europe";
            case "australia":
            case "new zealand":
                return "Oceania";
            case "south africa":
                return "Africa";
            default:
                return "Unknown";
        }
    }
    
    @GetMapping("/country-codes")
    public ResponseEntity<Map<String, String>> getAllCountryCodes() {
        Map<String, String> allCodes = countryCodeService.getAllCountryCodes();
        return ResponseEntity.ok(allCodes);
    }

    @GetMapping("/validate-country/{countryName}")
    public ResponseEntity<Map<String, Object>> validateCountryName(@PathVariable String countryName) {
        boolean isValid = countryValidationService.isValidCountry(countryName);
        List<String> suggestions = isValid ? List.of() : countryValidationService.getSuggestions(countryName);
        
        Map<String, Object> response = Map.of(
            "countryName", countryName,
            "isValid", isValid,
            "suggestions", suggestions
        );
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/supported-countries")
    public ResponseEntity<Set<String>> getSupportedCountries() {
        Set<String> supportedCountries = countryValidationService.getAllSupportedCountries();
        return ResponseEntity.ok(supportedCountries);
    }
}