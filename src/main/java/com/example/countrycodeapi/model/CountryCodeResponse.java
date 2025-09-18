package com.example.countrycodeapi.model;

public class CountryCodeResponse {
    private String countryName;
    private String countryCode;
    private String region;

    public CountryCodeResponse(String countryName, String countryCode, String region) {
        this.countryName = countryName;
        this.countryCode = countryCode;
        this.region = region;
    }

    public String getCountryName() {
        return countryName;
    }

    public void setCountryName(String countryName) {
        this.countryName = countryName;
    }

    public String getCountryCode() {
        return countryCode;
    }

    public void setCountryCode(String countryCode) {
        this.countryCode = countryCode;
    }

    public String getRegion() {
        return region;
    }

    public void setRegion(String region) {
        this.region = region;
    }
}