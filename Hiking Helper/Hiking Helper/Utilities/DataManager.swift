//
//  DataManager.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 11/5/25.
//

import Foundation
import Combine

class DataManager: ObservableObject {
    
    @Published var allTrails: [Trail] = []
    @Published var isLoading: Bool = false
    @Published var lastLoadedDate: Date?
    @Published var loadedStates: [String] = []  // Track which states are loaded
    
    private var hasLoadedData = false
    
    // Reference to user preferences
    var userPreferences: UserPreferences
    
    init(userPreferences: UserPreferences) {
        self.userPreferences = userPreferences
    }
    
    // COMPUTED property - filters cached data without reloading
    var filteredTrails: [Trail] {
        let prefs = userPreferences.trailPreferences
        
        return allTrails.filter { trail in
            // Distance filter
            guard trail.distanceMiles >= prefs.minDistance && trail.distanceMiles <= prefs.maxDistance else {
                return false
            }
            
            // Difficulty filter
            if !prefs.difficulty.isEmpty {
                guard trail.difficultyLevel.lowercased() == prefs.difficulty.lowercased() else {
                    return false
                }
            }
            
            // Elevation filter
            if !prefs.elevation.isEmpty {
                let matchesElevation: Bool
                switch prefs.elevation.lowercased() {
                case "low":
                    matchesElevation = trail.elevationGainFeet < 500
                case "moderate":
                    matchesElevation = trail.elevationGainFeet >= 500 && trail.elevationGainFeet < 1500
                case "high":
                    matchesElevation = trail.elevationGainFeet >= 1500
                default:
                    matchesElevation = true
                }
                guard matchesElevation else { return false }
            }
            
            // State filter - trail must be in one of selected states
            if !prefs.selectedStates.isEmpty {
                let trailStateCode = getStateCode(from: trail.state)
                guard prefs.selectedStates.contains(trailStateCode) else {
                    return false
                }
            }
            
            return true
        }
    }
    
    // Helper to get state code from trail's state field
    private func getStateCode(from stateString: String) -> String {
        // If it's already a 2-letter code
        if stateString.count == 2 {
            return stateString.uppercased()
        }
        // Otherwise, try to find the code from the name
        return StateData.stateCode(for: stateString) ?? stateString.uppercased()
    }
    
    // MARK: - Loading Methods
    
    // Load data based on selected states
    func loadTrailsIfNeeded() {
        let selectedStates = userPreferences.trailPreferences.selectedStates
        
        // If no states selected, try loading default/test data
        if selectedStates.isEmpty {
            loadDefaultTrails()
            return
        }
        
        // Check if we need to reload (states changed)
        let statesChanged = Set(loadedStates) != Set(selectedStates)
        
        if !hasLoadedData || statesChanged {
            loadTrailsForStates(selectedStates)
        } else {
            print("✅ Data already loaded for states: \(loadedStates)")
        }
    }
    
    // Load trails from multiple state JSON files
    func loadTrailsForStates(_ states: [String]) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var combinedTrails: [Trail] = []
            var loadedStatesList: [String] = []
            
            for stateCode in states {
                let filename = "trails_\(stateCode.uppercased())"
                
                if let stateTrails = JSONLoader.load(filename, as: [Trail].self) {
                    combinedTrails.append(contentsOf: stateTrails)
                    loadedStatesList.append(stateCode)
                    print("✅ Loaded \(stateTrails.count) trails from \(filename).json")
                } else {
                    print("⚠️ No trail data found for \(stateCode) (looked for \(filename).json)")
                }
            }
            
            DispatchQueue.main.async {
                self?.allTrails = combinedTrails
                self?.loadedStates = loadedStatesList
                self?.hasLoadedData = true
                self?.lastLoadedDate = Date()
                self?.isLoading = false
                print("✅ Total trails loaded: \(combinedTrails.count) from \(loadedStatesList.count) states")
            }
        }
    }
    
    // Load default/test trails (fallback)
    private func loadDefaultTrails() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let loadedTrails = JSONLoader.load("testTrails", as: [Trail].self) {
                DispatchQueue.main.async {
                    self?.allTrails = loadedTrails
                    self?.hasLoadedData = true
                    self?.lastLoadedDate = Date()
                    self?.isLoading = false
                    print("✅ Loaded \(loadedTrails.count) trails from testTrails.json")
                }
            } else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    print("❌ Failed to load default trails")
                }
            }
        }
    }
    
    // Force reload for selected states
    func loadTrails() {
        let selectedStates = userPreferences.trailPreferences.selectedStates
        if selectedStates.isEmpty {
            loadDefaultTrails()
        } else {
            loadTrailsForStates(selectedStates)
        }
    }
    
    // Refresh data (for pull-to-refresh)
    func refresh() {
        hasLoadedData = false
        loadTrails()
    }
    
    // Reload when states change
    func reloadForStateChange() {
        hasLoadedData = false
        loadTrailsIfNeeded()
    }
    
    // Clear cache
    func clearCache() {
        allTrails = []
        loadedStates = []
        hasLoadedData = false
        lastLoadedDate = nil
    }
    
    // Add trails for a specific state (without clearing existing)
    func addTrailsForState(_ stateCode: String) {
        let filename = "trails_\(stateCode.uppercased())"
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            if let stateTrails = JSONLoader.load(filename, as: [Trail].self) {
                DispatchQueue.main.async {
                    // Remove any existing trails from this state first
                    self?.allTrails.removeAll { trail in
                        self?.getStateCode(from: trail.state) == stateCode.uppercased()
                    }
                    // Add new trails
                    self?.allTrails.append(contentsOf: stateTrails)
                    if !(self?.loadedStates.contains(stateCode) ?? false) {
                        self?.loadedStates.append(stateCode)
                    }
                    print("✅ Added \(stateTrails.count) trails for \(stateCode)")
                }
            }
        }
    }
    
    // Remove trails for a specific state
    func removeTrailsForState(_ stateCode: String) {
        allTrails.removeAll { trail in
            getStateCode(from: trail.state) == stateCode.uppercased()
        }
        loadedStates.removeAll { $0 == stateCode }
        print("🗑️ Removed trails for \(stateCode)")
    }
}

// MARK: - Additional Filtering Methods
extension DataManager {
    
    // Get trails for a specific state
    func trails(forState stateCode: String) -> [Trail] {
        return allTrails.filter { trail in
            getStateCode(from: trail.state) == stateCode.uppercased()
        }
    }
    
    // Get trails filtered by specific difficulty
    func trails(withDifficulty difficulty: String) -> [Trail] {
        return filteredTrails.filter { trail in
            trail.difficultyLevel.lowercased() == difficulty.lowercased()
        }
    }
    
    // Get trails within a specific distance range
    func trails(minDistance: Double, maxDistance: Double) -> [Trail] {
        return allTrails.filter { trail in
            trail.distanceMiles >= minDistance && trail.distanceMiles <= maxDistance
        }
    }
    
    // Get beginner-friendly trails
    var beginnerTrails: [Trail] {
        return filteredTrails.filter { trail in
            trail.distanceMiles <= 3.0 && trail.difficultyLevel.lowercased() == "easy"
        }
    }
    
    // Get trails matching user's goal
    var progressionTrails: [Trail] {
        let prefs = userPreferences.trailPreferences
        
        if prefs.wantsToProgress {
            let targetDistance = prefs.maxDistance * 1.2
            return allTrails.filter { trail in
                trail.distanceMiles > prefs.maxDistance &&
                trail.distanceMiles <= targetDistance
            }
        }
        
        return filteredTrails
    }
    
    // Get count of trails per state
    var trailCountByState: [String: Int] {
        var counts: [String: Int] = [:]
        for trail in allTrails {
            let stateCode = getStateCode(from: trail.state)
            counts[stateCode, default: 0] += 1
        }
        return counts
    }
}
