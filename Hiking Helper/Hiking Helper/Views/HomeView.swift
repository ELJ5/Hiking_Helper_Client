//
//  HomeView.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 10/16/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var goalDataManager: GoalDataManager
    
    @State private var navigateToProfile = false
    @State private var navigateToChatbot = false
    @State private var navigateToGoals = false
    @State private var searchText = ""
    @State private var showAllRecommended = false
    @State private var showAllEasier = false
    @State private var showAllOther = false
    
    // Standard initializer
    init() {
        self._goalDataManager = StateObject(wrappedValue: GoalDataManager())
    }
    
    // Preview/test initializer with test data
    init(withTestData: Bool) {
        self._goalDataManager = StateObject(wrappedValue: GoalDataManager(withTestData: withTestData))
    }
    
    // Trails that match user preferences perfectly
    func getMatchingTrails() -> [Trail] {
        let prefs = userPreferences.trailPreferences
        
        return dataManager.allTrails.filter { trail in
            // Filter by selected states
            if !prefs.selectedStates.isEmpty {
                let trailStateCode = getStateCode(from: trail.state)
                guard prefs.selectedStates.contains(trailStateCode) else {
                    return false
                }
            }
            
            // Filter by difficulty - exact match
            let matchesDifficulty = trail.difficultyLevel.lowercased() == prefs.difficulty.lowercased()
            
            // Filter by distance range - within range
            let matchesDistance = trail.distanceMiles >= prefs.minDistance && trail.distanceMiles <= prefs.maxDistance
            
            // Filter by elevation preference - within range
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
            
            return matchesDifficulty && matchesDistance && matchesElevation
        }
    }
    
    // Trails that are easier than user preferences (for building up)
    func getEasierTrails() -> [Trail] {
        let prefs = userPreferences.trailPreferences
        let perfectMatchIds = Set(getMatchingTrails().map { $0.id })
        
        return dataManager.allTrails.filter { trail in
            // Don't include trails that already perfectly match
            guard !perfectMatchIds.contains(trail.id) else {
                return false
            }
            
            // Filter by selected states
            if !prefs.selectedStates.isEmpty {
                let trailStateCode = getStateCode(from: trail.state)
                guard prefs.selectedStates.contains(trailStateCode) else {
                    return false
                }
            }
            
            // Check if trail is easier in at least one dimension
            let isEasierDifficulty = isDifficultyEasierOrEqual(trail.difficultyLevel, than: prefs.difficulty)
            let isShorterDistance = trail.distanceMiles <= prefs.maxDistance
            let isLowerElevation = isElevationLowerOrEqual(trail.elevationGainFeet, than: prefs.elevation)
            
            // Must be easier in at least one way and not harder in others
            return isEasierDifficulty && isShorterDistance && isLowerElevation
        }
    }
    
    // Trails that don't match user preferences (for exploration)
    func getNonMatchingTrails() -> [Trail] {
        let matchingIds = Set(getMatchingTrails().map { $0.id })
        let easierIds = Set(getEasierTrails().map { $0.id })
        let excludedIds = matchingIds.union(easierIds)
        
        var results = dataManager.allTrails.filter { !excludedIds.contains($0.id) }
        
        // Apply search filter if text entered
        if !searchText.isEmpty {
            results = results.filter { trail in
                trail.trailName.localizedCaseInsensitiveContains(searchText) ||
                trail.state.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return results
    }
    
    // Helper to check if difficulty is easier or equal
    private func isDifficultyEasierOrEqual(_ trailDifficulty: String, than preferredDifficulty: String) -> Bool {
        let difficultyLevels = ["easy": 1, "moderate": 2, "hard": 3, "very hard": 4]
        let trailLevel = difficultyLevels[trailDifficulty.lowercased()] ?? 2
        let preferredLevel = difficultyLevels[preferredDifficulty.lowercased()] ?? 2
        return trailLevel <= preferredLevel
    }
    
    // Helper to check if elevation is lower or equal
    private func isElevationLowerOrEqual(_ trailElevation: Double, than preferredElevation: String) -> Bool {
        switch preferredElevation.lowercased() {
        case "low":
            return trailElevation < 500
        case "moderate":
            return trailElevation < 1500
        case "high":
            return true // Everything is <= high
        default:
            return true
        }
    }
    
    // Helper to get state code from trail's state field
    private func getStateCode(from stateString: String) -> String {
        if stateString.count == 2 {
            return stateString.uppercased()
        }
        return StateData.stateCode(for: stateString) ?? stateString.uppercased()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with buttons
            HStack {
                Button(action: {
                    navigateToChatbot = true
                }) {
                    Image(systemName: "message.fill")
                        .font(.title)
                        .foregroundColor(.green)
                        .padding(.leading, 20)
                        .padding(.top, 10)
                }
                .navigationDestination(isPresented: $navigateToChatbot) {
                    ChatbotView()
                        .environmentObject(userPreferences)
                        .environmentObject(dataManager)
                }
                
                Spacer()
                
                Button(action: {
                    navigateToProfile = true
                    print("hit button")
                }) {
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                }
                .navigationDestination(isPresented: $navigateToProfile) {
                    ProfileView()
                        .environmentObject(userPreferences)
                        .environmentObject(dataManager)
                }
            }
            .padding(.bottom, 10)
            
            // Main content
            ScrollView {
                VStack(spacing: 20) {
                    // Progress and Checklist section
                    HStack(alignment: .top, spacing: 20) {
                        // Progress Circle
                        VStack {
                            Text("Progress")
                                .font(.headline)
                            Text("\(Int(goalDataManager.completionPercentage))%")
                                .font(.title2)
                                .bold()
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(goalDataManager.completionPercentage / 100))
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.green, .blue]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goalDataManager.completionPercentage)
                                
                                // Center stats
                                VStack(spacing: 2) {
                                    Text("\(goalDataManager.completedGoals.count)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                    Text("of \(goalDataManager.goals.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(width: 125, height: 125)
                            .padding()
                        }
                        
                        // Checklist
                        VStack {
                            HStack {
                                Text("Goals")
                                    .font(.headline)
                                    .padding(.top, 15)
                                
                                Spacer()
                                
                                Button(action: {
                                    navigateToGoals = true
                                }) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.green)
                                        .padding(.top, 15)
                                }
                            }
                            .padding(.horizontal)
                            
                            if goalDataManager.pendingGoals.isEmpty && goalDataManager.goals.isEmpty {
                                // Empty state
                                VStack(spacing: 8) {
                                    Image(systemName: "target")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                    Text("No goals yet")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button(action: {
                                        navigateToGoals = true
                                    }) {
                                        Text("Add Goals")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.green)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                            } else if goalDataManager.pendingGoals.isEmpty {
                                // All completed state
                                VStack(spacing: 8) {
                                    Image(systemName: "trophy.fill")
                                        .font(.title2)
                                        .foregroundColor(.yellow)
                                    Text("All done!")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                            } else {
                                // Goals list
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 10) {
                                        ForEach(goalDataManager.pendingGoals.prefix(6)) { goal in
                                            HStack {
                                                Button(action: {
                                                    goalDataManager.toggleGoalCompletion(id: goal.id)
                                                }) {
                                                    Image(systemName: "circle")
                                                        .foregroundColor(.green)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(goal.title)
                                                        .font(.subheadline)
                                                        .lineLimit(1)
                                                    
                                                    Text(goal.category.rawValue)
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        
                                        if goalDataManager.pendingGoals.count > 6 {
                                            Text("+\(goalDataManager.pendingGoals.count - 6) more")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.top, 4)
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }
                        .frame(height: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemGray6))
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                    
                    // Recommended Trails (matching preferences)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recommended For You")
                                .font(.title2)
                                .bold()
                            
                            Spacer()
                            
                            Text("\(getMatchingTrails().count) trails")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if getMatchingTrails().isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "leaf")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                                Text("No trails match your preferences")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Try adjusting your settings in Profile")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(getMatchingTrails().prefix(showAllRecommended ? getMatchingTrails().count : 3)) { trail in
                                    TrailSearchResultRow(
                                        trail: trail,
                                        isCompleted: userPreferences.trailPreferences.isTrailCompleted(trail.id)
                                    )
                                }
                                
                                if getMatchingTrails().count > 3 {
                                    Button(action: {
                                        withAnimation {
                                            showAllRecommended.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Text(showAllRecommended ? "Show Less" : "Show \(getMatchingTrails().count - 3) More")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Image(systemName: showAllRecommended ? "chevron.up" : "chevron.down")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.blue)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Build Up Trails (easier than preferences)
                    if !getEasierTrails().isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Build Up To Your Goals")
                                        .font(.title2)
                                        .bold()
                                    Text("Easier trails to help you progress")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(getEasierTrails().count) trails")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(spacing: 10) {
                                ForEach(getEasierTrails().prefix(showAllEasier ? getEasierTrails().count : 3)) { trail in
                                    TrailSearchResultRow(
                                        trail: trail,
                                        isCompleted: userPreferences.trailPreferences.isTrailCompleted(trail.id)
                                    )
                                }
                                
                                if getEasierTrails().count > 3 {
                                    Button(action: {
                                        withAnimation {
                                            showAllEasier.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Text(showAllEasier ? "Show Less" : "Show \(getEasierTrails().count - 3) More")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Image(systemName: showAllEasier ? "chevron.up" : "chevron.down")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.green)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Explore Other Trails (non-matching)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Explore Other Trails")
                                .font(.title2)
                                .bold()
                            
                            Spacer()
                            
                            Text("\(getNonMatchingTrails().count) trails")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Search Bar for other trails
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search by name or state", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                            
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        if getNonMatchingTrails().isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                                Text(searchText.isEmpty ? "All trails match your preferences!" : "No trails found")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(getNonMatchingTrails().prefix(showAllOther ? getNonMatchingTrails().count : 2)) { trail in
                                    TrailSearchResultRow(
                                        trail: trail,
                                        isCompleted: userPreferences.trailPreferences.isTrailCompleted(trail.id)
                                    )
                                }
                                
                                if getNonMatchingTrails().count > 2 {
                                    Button(action: {
                                        withAnimation {
                                            showAllOther.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Text(showAllOther ? "Show Less" : "Show \(getNonMatchingTrails().count - 2) More")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Image(systemName: showAllOther ? "chevron.up" : "chevron.down")
                                                .font(.caption)
                                        }
                                        .foregroundColor(.orange)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.orange.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Nearby Hikes section
                    VStack {
                        Text("Nearby Hikes")
                            .font(.title2)
                            .bold()
                            .padding(.top, 20)
                        
                        // Placeholder for map
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemGray6))
                                .frame(height: 300)
                            
                            VStack {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                                Text("Map Coming Soon")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 10)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToGoals) {
            GoalsView(userPreferences: userPreferences, goalDataManager: goalDataManager)
        }
        .onAppear {
            // Load trails if not already loaded
            dataManager.loadTrailsIfNeeded()
            print("📍 HomeView appeared - allTrails count: \(dataManager.allTrails.count)")
        }
    }
}

// MARK: - Trail Search Result Row

struct TrailSearchResultRow: View {
    let trail: Trail
    let isCompleted: Bool
    
    var body: some View {
        NavigationLink {
            TrailDetailView(trail: trail)
        } label: {
            HStack(spacing: 12) {
                // Difficulty indicator
                Circle()
                    .fill(difficultyColor)
                    .frame(width: 10, height: 10)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(trail.trailName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Label(String(format: "%.1f mi", trail.distanceMiles), systemImage: "figure.walk")
                        Label("\(Int(trail.elevationGainFeet)) ft", systemImage: "arrow.up.right")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Difficulty badge
                Text(trail.difficultyLevel)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor.opacity(0.1))
                    .foregroundColor(difficultyColor)
                    .cornerRadius(4)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    private var difficultyColor: Color {
        switch trail.difficultyLevel.lowercased() {
        case "easy":
            return .green
        case "moderate":
            return .orange
        case "hard", "difficult", "challenging":
            return .red
        default:
            return .gray
        }
    }
}


#Preview {
    let prefs = UserPreferences()
    let dataManager = DataManager(userPreferences: prefs)
    
    return NavigationStack {
        HomeView(withTestData: true)
            .environmentObject(prefs)
            .environmentObject(dataManager)
    }
}
