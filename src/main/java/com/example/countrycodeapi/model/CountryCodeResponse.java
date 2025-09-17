package com.example.countrycodeapi.model;

public class CountryCodeResponse {
    private String countryCode;

    public CountryCodeResponse(String countryCode) {
        this.countryCode = countryCode;
    }

    public String getCountryCode() {
        return countryCode;
    }

    public void setCountryCode(String countryCode) {
        this.countryCode = countryCode;
    }
}