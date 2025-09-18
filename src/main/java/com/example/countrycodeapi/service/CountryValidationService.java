package com.example.countrycodeapi.service;

import org.springframework.stereotype.Service;
import java.util.Set;
import java.util.HashSet;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class CountryValidationService {

    private static final Set<String> VALID_COUNTRIES = new HashSet<>(Arrays.asList(
        "India", "United States", "United Kingdom", "Germany", "France",
        "Canada", "Australia", "Japan", "Brazil", "Mexico", "Italy",
        "China", "South Africa", "New Zealand", "Argentina"
    ));

    private static final Set<String> COMMON_MISSPELLINGS = new HashSet<>(Arrays.asList(
        "US", "USA", "UK", "Britain", "Deutschland", "Deutchland"
    ));

    /**
     * Validates if a country name is supported
     */
    public boolean isValidCountry(String countryName) {
        if (countryName == null || countryName.trim().isEmpty()) {
            return false;
        }
        return VALID_COUNTRIES.contains(normalize(countryName));
    }

    /**
     * Gets suggestions for similar country names
     */
    public List<String> getSuggestions(String countryName) {
        if (countryName == null || countryName.trim().isEmpty()) {
            return List.of();
        }

        String normalizedInput = normalize(countryName);
        
        // Check for common misspellings
        if (COMMON_MISSPELLINGS.contains(normalizedInput)) {
            return getCommonMisspellingSuggestions(normalizedInput);
        }

        // Find partial matches
        return VALID_COUNTRIES.stream()
                .filter(country -> country.toLowerCase().contains(normalizedInput.toLowerCase()) ||
                                 normalizedInput.toLowerCase().contains(country.toLowerCase()) ||
                                 levenshteinDistance(normalizedInput.toLowerCase(), country.toLowerCase()) <= 2)
                .limit(3)
                .collect(Collectors.toList());
    }

    /**
     * Get all supported countries
     */
    public Set<String> getAllSupportedCountries() {
        return new HashSet<>(VALID_COUNTRIES);
    }

    /**
     * Normalize country name for comparison
     */
    private String normalize(String countryName) {
        return countryName.trim()
                .replaceAll("\\s+", " ")
                .toLowerCase()
                .substring(0, 1).toUpperCase() + 
                countryName.trim().replaceAll("\\s+", " ").toLowerCase().substring(1);
    }

    private List<String> getCommonMisspellingSuggestions(String misspelling) {
        switch (misspelling.toLowerCase()) {
            case "us":
            case "usa":
                return List.of("United States");
            case "uk":
            case "britain":
                return List.of("United Kingdom");
            case "deutschland":
            case "deutchland":
                return List.of("Germany");
            default:
                return List.of();
        }
    }

    /**
     * Simple Levenshtein distance calculation
     */
    private int levenshteinDistance(String a, String b) {
        int[][] dp = new int[a.length() + 1][b.length() + 1];

        for (int i = 0; i <= a.length(); i++) {
            for (int j = 0; j <= b.length(); j++) {
                if (i == 0) {
                    dp[i][j] = j;
                } else if (j == 0) {
                    dp[i][j] = i;
                } else {
                    dp[i][j] = Math.min(
                        Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
                        dp[i - 1][j - 1] + (a.charAt(i - 1) == b.charAt(j - 1) ? 0 : 1)
                    );
                }
            }
        }
        return dp[a.length()][b.length()];
    }
}
