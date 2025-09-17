package com.example.countrycodeapi.service;

import org.springframework.stereotype.Service;
import com.example.countrycodeapi.exception.CountryNotFoundException;

import java.util.HashMap;
import java.util.Map;

@Service
public class CountryCodeService {

    private static final Map<String, String> COUNTRY_CODES = new HashMap<>();

    static {
        COUNTRY_CODES.put("India", "+91");
        COUNTRY_CODES.put("United States", "+1");
        COUNTRY_CODES.put("United Kingdom", "+44");
        COUNTRY_CODES.put("Canada", "+1");
        COUNTRY_CODES.put("Australia", "+61");
        COUNTRY_CODES.put("New Zealand", "+64");
        COUNTRY_CODES.put("South Africa", "+27");
        COUNTRY_CODES.put("Brazil", "+55");
        COUNTRY_CODES.put("Mexico", "+52");
        COUNTRY_CODES.put("Argentina", "+54");
        // Add more countries as needed
    }

    public String getCountryCode(String countryName) {
        String countryCode = COUNTRY_CODES.get(countryName);
        if (countryCode == null) {
            throw new CountryNotFoundException("Country not found: " + countryName);
        }
        return countryCode;
    }
}