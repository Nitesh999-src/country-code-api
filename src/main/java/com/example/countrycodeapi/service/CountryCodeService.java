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