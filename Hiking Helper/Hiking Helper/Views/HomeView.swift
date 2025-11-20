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
    
    // Standard initializer
    init() {
        self._goalDataManager = StateObject(wrappedValue: GoalDataManager())
    }
    
    // Preview/test initializer with test data
    init(withTestData: Bool) {
        self._goalDataManager = StateObject(wrappedValue: GoalDataManager(withTestData: withTestData))
    }
    
    // Trails that match user preferences
    func getMatchingTrails() -> [Trail] {
        let prefs = userPreferences.trailPreferences
        
        return dataManager.allTrails.filter { trail in
            // Filter by difficulty
            let matchesDifficulty = trail.difficultyLevel.lowercased() == prefs.difficulty.lowercased()
            
            // Filter by distance range
            let matchesDistance = trail.distanceMiles >= prefs.minDistance && trail.distanceMiles <= prefs.maxDistance
            
            // Filter by elevation preference
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
    
    // Trails that don't match user preferences (for exploration)
    func getNonMatchingTrails() -> [Trail] {
        let matchingIds = Set(getMatchingTrails().map { $0.id })
        var results = dataManager.allTrails.filter { !matchingIds.contains($0.id) }
        
        // Apply search filter if text entered
        if !searchText.isEmpty {
            results = results.filter { trail in
                trail.trailName.localizedCaseInsensitiveContains(searchText) ||
                trail.state.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return results
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
                                
                                Spacer()
                                
                                Button(action: {
                                    navigateToGoals = true
                                }) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.green)
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
                                ForEach(getMatchingTrails()) { trail in
                                    TrailSearchResultRow(
                                        trail: trail,
                                        isCompleted: userPreferences.trailPreferences.isTrailCompleted(trail.id)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
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
                                ForEach(getNonMatchingTrails().prefix(10)) { trail in
                                    TrailSearchResultRow(
                                        trail: trail,
                                        isCompleted: userPreferences.trailPreferences.isTrailCompleted(trail.id)
                                    )
                                }
                                
                                if getNonMatchingTrails().count > 10 {
                                    Text("+\(getNonMatchingTrails().count - 10) more trails")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
    }
}

// MARK: - Trail Search Result Row

struct TrailSearchResultRow: View {
    let trail: Trail
    let isCompleted: Bool
    
    var body: some View {
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
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
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
