package com.example.countrycodeapi.controller;

import com.example.countrycodeapi.exception.CountryNotFoundException;
import com.example.countrycodeapi.model.CountryCodeResponse;
import com.example.countrycodeapi.service.CountryCodeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CountryCodeController {

    private final CountryCodeService countryCodeService;

    @Autowired
    public CountryCodeController(CountryCodeService countryCodeService) {
        this.countryCodeService = countryCodeService;
    }

    @GetMapping("/country-code/{countryName}")
    public ResponseEntity<CountryCodeResponse> getCountryCode(@PathVariable String countryName) {
        String countryCode = countryCodeService.getCountryCode(countryName);
        if (countryCode == null) {
            throw new CountryNotFoundException("Country not found: " + countryName);
        }
        return ResponseEntity.ok(new CountryCodeResponse(countryCode));
    }
}