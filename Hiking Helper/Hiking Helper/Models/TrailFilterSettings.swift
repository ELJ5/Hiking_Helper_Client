//
//  TrailFilterSettings.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 11/1/25.
//

import Foundation

struct FilterPreferences: Codable {
    // Hiking-specific preferences
    var difficulty: String
    var minDistance: Double
    var maxDistance: Double
    var elevation: String
    var helper: Bool
    var location: String
    var travelRadius: String  // Distance willing to travel

    
    // Experience level
    var hikingFrequency: String
    var currentCapability: String
    var desiredDistance: String
    
    // Onboarding
    var hasCompletedOnboarding: Bool
    
    static let `default` = FilterPreferences(
        difficulty: "Easy",
        minDistance: 1.5,
        maxDistance: 3.0,
        elevation: "Low",
        helper: true,
        location: "SC",
        travelRadius: "<60 miles",
        hikingFrequency: "Never have",
        currentCapability: "0-2 miles",
        desiredDistance: "0-2 miles",
        hasCompletedOnboarding: false
    )
}
