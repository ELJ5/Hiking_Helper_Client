//
//  UserPreferences.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 11/5/25.
//

import Foundation

class UserPreferences: ObservableObject {
    @Published var trailPreferences: TrailPreferences {
        didSet {
            save()  // Auto-save whenever preferences change
        }
    }
    
    private let preferencesKey = "userTrailPreferences"
    
    init() {
        // Load saved preferences on init
        self.trailPreferences = UserPreferences.load()
    }
    
    // Load preferences from UserDefaults
    static func load() -> TrailPreferences {
        guard let data = UserDefaults.standard.data(forKey: "userTrailPreferences"),
              let preferences = try? JSONDecoder().decode(TrailPreferences.self, from: data) else {
            return TrailPreferences.default
        }
        return preferences
    }
    
    // Save preferences to UserDefaults
    private func save() {
        guard let data = try? JSONEncoder().encode(trailPreferences) else { return }
        UserDefaults.standard.set(data, forKey: preferencesKey)
    }
    
    // Reset to defaults
    func reset() {
        trailPreferences = TrailPreferences.default
    }
    
    // Check if onboarding is complete
    var needsOnboarding: Bool {
        !trailPreferences.hasCompletedOnboarding
    }
}

// MARK: - Trail Preferences Model
struct TrailPreferences: Codable {
    var helper: Bool
    var hikingFrequency: String
    var desiredDistance: String
    var currentCapability: String
    var difficulty: String
    var elevation: String
    var location: String?  // Keep for backward compatibility
    var selectedStates: [String]  // NEW: Array of selected state codes (e.g., ["SC", "NC", "GA"])
    var travelRadius: String
    var hasCompletedOnboarding: Bool
    var minDistance: Double
    var maxDistance: Double
    
    // Track completed trails by their IDs
    var completedTrails: [Int]
    
    // Default values
    static var `default`: TrailPreferences {
        TrailPreferences(
            helper: false,
            hikingFrequency: "",
            desiredDistance: "",
            currentCapability: "",
            difficulty: "Easy",
            elevation: "Low",
            location: "SC",
            selectedStates: [],  // Empty array by default
            travelRadius: "",
            hasCompletedOnboarding: false,
            minDistance: 0.0,
            maxDistance: 10.0,
            completedTrails: []
        )
    }
}

// MARK: - Convenience Extensions
extension TrailPreferences {
    // Check if user is a beginner
    var isBeginner: Bool {
        return hikingFrequency == "Never have" ||
               hikingFrequency == "Once a year" ||
               currentCapability == "0-2 miles"
    }
    
    // Check if user wants to progress
    var wantsToProgress: Bool {
        return helper && currentCapability != desiredDistance
    }
    
    // Get distance as a range for display
    var distanceRangeText: String {
        return String(format: "%.1f - %.1f miles", minDistance, maxDistance)
    }
    
    // Check if all required fields are filled
    var isComplete: Bool {
        return !hikingFrequency.isEmpty &&
               !desiredDistance.isEmpty &&
               !currentCapability.isEmpty &&
               !difficulty.isEmpty &&
               !elevation.isEmpty &&
               hasCompletedOnboarding
    }
    
    // Check if a trail is completed
    func isTrailCompleted(_ trailId: Int) -> Bool {
        return completedTrails.contains(trailId)
    }
    
    // Number of completed trails
    var completedTrailCount: Int {
        return completedTrails.count
    }
    
    // Check if any states are selected
    var hasSelectedStates: Bool {
        return !selectedStates.isEmpty
    }
    
    // Get selected states as display string
    var selectedStatesText: String {
        if selectedStates.isEmpty {
            return "None selected"
        } else if selectedStates.count <= 3 {
            return selectedStates.joined(separator: ", ")
        } else {
            return "\(selectedStates.prefix(2).joined(separator: ", ")) +\(selectedStates.count - 2) more"
        }
    }
}

// MARK: - Completed Trail Management
extension UserPreferences {
    // Mark a trail as completed
    func markTrailCompleted(_ trailId: Int) {
        if !trailPreferences.completedTrails.contains(trailId) {
            trailPreferences.completedTrails.append(trailId)
        }
    }
    
    // Unmark a trail as completed
    func unmarkTrailCompleted(_ trailId: Int) {
        trailPreferences.completedTrails.removeAll { $0 == trailId }
    }
    
    // Toggle trail completion
    func toggleTrailCompletion(_ trailId: Int) {
        if trailPreferences.completedTrails.contains(trailId) {
            unmarkTrailCompleted(trailId)
        } else {
            markTrailCompleted(trailId)
        }
    }
    
    // Clear all completed trails
    func clearCompletedTrails() {
        trailPreferences.completedTrails = []
    }
}

// MARK: - State Selection Management
extension UserPreferences {
    // Add a state to selection
    func addState(_ stateCode: String) {
        if !trailPreferences.selectedStates.contains(stateCode) {
            trailPreferences.selectedStates.append(stateCode)
        }
    }
    
    // Remove a state from selection
    func removeState(_ stateCode: String) {
        trailPreferences.selectedStates.removeAll { $0 == stateCode }
    }
    
    // Toggle state selection
    func toggleState(_ stateCode: String) {
        if trailPreferences.selectedStates.contains(stateCode) {
            removeState(stateCode)
        } else {
            addState(stateCode)
        }
    }
    
    // Check if a state is selected
    func isStateSelected(_ stateCode: String) -> Bool {
        return trailPreferences.selectedStates.contains(stateCode)
    }
    
    // Clear all selected states
    func clearSelectedStates() {
        trailPreferences.selectedStates = []
    }
    
    // Set multiple states at once
    func setSelectedStates(_ states: [String]) {
        trailPreferences.selectedStates = states
    }
}

// MARK: - Available States
struct StateData {
    let code: String
    let name: String
    let hasTrailData: Bool
    
    static let allStates: [StateData] = [
        StateData(code: "AL", name: "Alabama", hasTrailData: false),
        StateData(code: "AK", name: "Alaska", hasTrailData: false),
        StateData(code: "AZ", name: "Arizona", hasTrailData: false),
        StateData(code: "AR", name: "Arkansas", hasTrailData: false),
        StateData(code: "CA", name: "California", hasTrailData: false),
        StateData(code: "CO", name: "Colorado", hasTrailData: false),
        StateData(code: "CT", name: "Connecticut", hasTrailData: false),
        StateData(code: "DE", name: "Delaware", hasTrailData: false),
        StateData(code: "FL", name: "Florida", hasTrailData: false),
        StateData(code: "GA", name: "Georgia", hasTrailData: false),
        StateData(code: "HI", name: "Hawaii", hasTrailData: false),
        StateData(code: "ID", name: "Idaho", hasTrailData: false),
        StateData(code: "IL", name: "Illinois", hasTrailData: false),
        StateData(code: "IN", name: "Indiana", hasTrailData: false),
        StateData(code: "IA", name: "Iowa", hasTrailData: false),
        StateData(code: "KS", name: "Kansas", hasTrailData: false),
        StateData(code: "KY", name: "Kentucky", hasTrailData: false),
        StateData(code: "LA", name: "Louisiana", hasTrailData: false),
        StateData(code: "ME", name: "Maine", hasTrailData: false),
        StateData(code: "MD", name: "Maryland", hasTrailData: false),
        StateData(code: "MA", name: "Massachusetts", hasTrailData: false),
        StateData(code: "MI", name: "Michigan", hasTrailData: false),
        StateData(code: "MN", name: "Minnesota", hasTrailData: false),
        StateData(code: "MS", name: "Mississippi", hasTrailData: false),
        StateData(code: "MO", name: "Missouri", hasTrailData: false),
        StateData(code: "MT", name: "Montana", hasTrailData: false),
        StateData(code: "NE", name: "Nebraska", hasTrailData: false),
        StateData(code: "NV", name: "Nevada", hasTrailData: false),
        StateData(code: "NH", name: "New Hampshire", hasTrailData: false),
        StateData(code: "NJ", name: "New Jersey", hasTrailData: false),
        StateData(code: "NM", name: "New Mexico", hasTrailData: false),
        StateData(code: "NY", name: "New York", hasTrailData: false),
        StateData(code: "NC", name: "North Carolina", hasTrailData: false),
        StateData(code: "ND", name: "North Dakota", hasTrailData: false),
        StateData(code: "OH", name: "Ohio", hasTrailData: false),
        StateData(code: "OK", name: "Oklahoma", hasTrailData: false),
        StateData(code: "OR", name: "Oregon", hasTrailData: false),
        StateData(code: "PA", name: "Pennsylvania", hasTrailData: false),
        StateData(code: "RI", name: "Rhode Island", hasTrailData: false),
        StateData(code: "SC", name: "South Carolina", hasTrailData: true),
        StateData(code: "SD", name: "South Dakota", hasTrailData: false),
        StateData(code: "TN", name: "Tennessee", hasTrailData: false),
        StateData(code: "TX", name: "Texas", hasTrailData: false),
        StateData(code: "UT", name: "Utah", hasTrailData: false),
        StateData(code: "VT", name: "Vermont", hasTrailData: false),
        StateData(code: "VA", name: "Virginia", hasTrailData: false),
        StateData(code: "WA", name: "Washington", hasTrailData: false),
        StateData(code: "WV", name: "West Virginia", hasTrailData: false),
        StateData(code: "WI", name: "Wisconsin", hasTrailData: false),
        StateData(code: "WY", name: "Wyoming", hasTrailData: false)
    ]
    
    // Get states that have trail data
    static var availableStates: [StateData] {
        allStates.filter { $0.hasTrailData }
    }
    
    // Get state name from code
    static func stateName(for code: String) -> String {
        allStates.first { $0.code == code }?.name ?? code
    }
    
    // Get state code from name
    static func stateCode(for name: String) -> String? {
        allStates.first { $0.name.lowercased() == name.lowercased() }?.code
    }
}
