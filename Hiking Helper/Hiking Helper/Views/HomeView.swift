//
//  HomeView.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 10/16/25.
//

import SwiftUI
import MapKit

struct HomeView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var goalDataManager: GoalDataManager
    
    @State private var showProfile = false
    @State private var showChatbot = false
    @State private var navigateToChatbot = false
    @State private var navigateToGoals = false
    @State private var searchText = ""
    @State private var showAllRecommended = false
    @State private var showAllEasier = false
    @State private var showAllOther = false
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedTrail: Trail?
    
    // initializer
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
            
            // Match Difficulty
            let matchesDifficulty = trail.difficultyLevel.lowercased() == prefs.difficulty.lowercased()
            
            // Trail Distance within range
            let matchesDistance = trail.distanceMiles >= prefs.minDistance && trail.distanceMiles <= prefs.maxDistance
            
            // Trail Elevation within range
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
    
    // Trails that are easier than user preferences
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
            
            // Check if trail is easier in at least one way
            let isEasierDifficulty = isDifficultyEasierOrEqual(trail.difficultyLevel, than: prefs.difficulty)
            let isShorterDistance = trail.distanceMiles <= prefs.maxDistance
            let isLowerElevation = isElevationLowerOrEqual(trail.elevationGainFeet, than: prefs.elevation)
            
            // Must be easier in at least one way and not harder in others
            return isEasierDifficulty && isShorterDistance && isLowerElevation
        }
    }
    
    // Rest of trails not matching preferences
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
        ZStack {
            VStack(spacing: 0) {
                if !showProfile && !showChatbot {
                    headerView
                    ScrollView {
                        VStack(spacing: 20) {
                            if userPreferences.trailPreferences.helper {
                                progressAndGoalsSection
                            }
                            recommendedTrailsSection
                            easierTrailsSection
                            exploreOtherTrailsSection
                            mapSection
                        }
                        .padding(.top, 10)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
                }
            }
            
            
            // Chatbot overlay
            if showChatbot {
                ChatbotView(isPresentedBot: $showChatbot)
                    .environmentObject(userPreferences)
                    .environmentObject(dataManager)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
                    .zIndex(1)
            }
            
            // Profile overlay
            if showProfile {
                ProfileView(isPresented: $showProfile)
                    .environmentObject(userPreferences)
                    .environmentObject(dataManager)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
                    .zIndex(1)
            }
        }

        .animation(.easeInOut(duration: 0.3), value: showChatbot)
        .animation(.easeInOut(duration: 0.3), value: showProfile)
        .navigationDestination(isPresented: $navigateToGoals) {
            GoalsView(userPreferences: userPreferences, goalDataManager: goalDataManager)
        }
        .onAppear {
            dataManager.loadTrailsIfNeeded()
            updateMapRegion()
        }
        .onChange(of: userPreferences.trailPreferences.selectedStates) { _, _ in
            updateMapRegion()
        }

    }

    
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            if userPreferences.trailPreferences.helper {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showChatbot.toggle()
                    }
                }) {
                    Image(systemName: showChatbot ? "xmark.circle.fill" : "message.fill")
                        .font(.title)
                        .foregroundColor(.primaryGreen)   
                        .padding(.leading, 20)
                        .padding(.top, 10)
                }
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showProfile.toggle()
                }
            }) {
                Image(systemName: showProfile ? "xmark.circle.fill" : "person.fill")
                    .font(.title)
                    .foregroundColor(.primaryGreen)   
                    .padding(.trailing, 20)
                    .padding(.top, 10)
            }
        }
        .padding(.bottom, 10)
        .zIndex(10)
    }
    
    private var progressAndGoalsSection: some View {
        HStack(alignment: .top, spacing: 20) {
            progressCircle
            goalsChecklist
        }
        .padding(.horizontal)
    }

    private var progressCircle: some View {
        VStack {
            Text("Progress")
                .font(.headline)
                .foregroundColor(.textPrimary)  // Added
            Text("\(Int(goalDataManager.completionPercentage))%")
                .font(.title2)
                .bold()
                .foregroundColor(.textPrimary)  // Added
            
            ZStack {
                Circle()
                    .stroke(.borderColor1, lineWidth: 10)   
                
                Circle()
                    .trim(from: 0, to: CGFloat(goalDataManager.completionPercentage / 100))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.primaryBlue, .primaryGreen]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goalDataManager.completionPercentage)
                
                VStack(spacing: 2) {
                    Text("\(goalDataManager.completedGoals.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryGreen)   
                    Text("of \(goalDataManager.goals.count)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)   
                }
            }
            .frame(width: 125, height: 125)
            .padding()
        }
        
    }

    private var goalsChecklist: some View {
        VStack {
            HStack {
                Text("Goals")
                    .font(.headline)
                    .foregroundColor(.textPrimary)  // Added
                    .padding(.top, 15)
                
                Spacer()
                
                Button(action: {
                    navigateToGoals = true
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.primaryBlue)   
                        .padding(.top, 15)
                }
            }
            .padding(.horizontal)
            
            goalsContent
        }
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.surface)
        )
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var goalsContent: some View {
        if goalDataManager.pendingGoals.isEmpty && goalDataManager.goals.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.textSecondary)   
                Text("No goals yet")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Button(action: {
                    navigateToGoals = true
                }) {
                    Text("Add Goals")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryBlue)   
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else if goalDataManager.pendingGoals.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                Text("All done!")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(goalDataManager.pendingGoals.prefix(6)) { goal in
                        HStack {
                            Button(action: {
                                goalDataManager.toggleGoalCompletion(id: goal.id)
                            }) {
                                Image(systemName: "circle")
                                    .foregroundColor(.primaryBlue)   
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(goal.title)
                                    .font(.subheadline)
                                    .foregroundColor(.textPrimary)  // Added
                                    .lineLimit(1)
                                
                                Text(goal.category.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    
                    if goalDataManager.pendingGoals.count > 6 {
                        Text("+\(goalDataManager.pendingGoals.count - 6) more")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .padding(.top, 4)
                    }
                }
                .padding()
            }
        }
    }

    private var recommendedTrailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recommended For You")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.textPrimary)  // Added
                    Text("Trails matching your Preferences")
                        .font(.caption)
                        .foregroundColor(.textSecondary)   
                }
                
                Spacer()
                
                Text("\(getMatchingTrails().count) trails")
                    .font(.caption)
                    .foregroundColor(.textSecondary)   
            }
            
            recommendedTrailsList
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var recommendedTrailsList: some View {
        if getMatchingTrails().isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "leaf")
                    .font(.title)
                    .foregroundColor(.textSecondary)   
                Text("No trails match your preferences")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)   
                Text("Try adjusting your settings in Profile")
                    .font(.caption)
                    .foregroundColor(.textSecondary)   
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
                        .foregroundColor(.primaryBlue)   
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.primaryBlue.opacity(0.1))   
                        .cornerRadius(8)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    @ViewBuilder
    private var easierTrailsSection: some View {
        if !getEasierTrails().isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Helpful Trails")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.textPrimary)  // Added
                        Text("Easier trails to help you progress")
                            .font(.caption)
                            .foregroundColor(.textSecondary)   
                    }
                    
                    Spacer()
                    
                    Text("\(getEasierTrails().count) trails")
                        .font(.caption)
                        .foregroundColor(.textSecondary)   
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
                            .foregroundColor(.primaryGreen)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.lightGreen.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var exploreOtherTrailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Explore Other Trails")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.textPrimary)  // Added
                
                Spacer()
                
                Text("\(getNonMatchingTrails().count) trails")
                    .font(.caption)
                    .foregroundColor(.textSecondary)   
            }
            
            searchBar
            otherTrailsList
        }
        .padding(.horizontal)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)   
            
            TextField("Search by name or state", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textSecondary)   
                }
            }
        }
        .padding(12)
        .background(Color.surface)   
        .cornerRadius(10)
    }

    @ViewBuilder
    private var otherTrailsList: some View {
        if getNonMatchingTrails().isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.title)
                    .foregroundColor(.textSecondary)
                Text(searchText.isEmpty ? "All trails match your preferences!" : "No trails found")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
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
                        .foregroundColor(.accentBlue)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.accentBlue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Trails Map")
                .font(.title2)
                .bold()
                .foregroundColor(.textPrimary)
                .padding(.top, 20)
            
            mapContent
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var mapContent: some View {
        if getMatchingTrails().isEmpty {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.surface)
                    .frame(height: 300)
                
                VStack {
                    Image(systemName: "map.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.primaryBlue)
                    Text("No recommended trails to show")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        } else {
            Map(position: $cameraPosition, selection: $selectedTrail) {
                ForEach(getMatchingTrails()) { trail in
                    Annotation(trail.trailName, coordinate: CLLocationCoordinate2D(
                        latitude: trail.latitude,
                        longitude: trail.longitude
                    )) {
                        VStack(spacing: 0) {
                            Image(systemName: "figure.hiking")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(difficultyColor(for: trail.difficultyLevel))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                            
                            Image(systemName: "triangle.fill")
                                .font(.caption)
                                .foregroundColor(difficultyColor(for: trail.difficultyLevel))
                                .rotationEffect(.degrees(180))
                                .offset(y: -5)
                        }
                    }
                    .tag(trail)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 300)
            .cornerRadius(15)
            
            if let selectedTrail = selectedTrail {
                selectedTrailCard(selectedTrail)
            }
        }
    }

    private func selectedTrailCard(_ trail: Trail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trail.trailName)
                        .font(.headline)
                        .foregroundColor(.textPrimary)  // Added

                    
                    HStack(spacing: 12) {
                        Label(String(format: "%.1f mi", trail.distanceMiles), systemImage: "figure.walk")
                        Label("\(Int(trail.elevationGainFeet)) ft", systemImage: "arrow.up.right")
                        Text(trail.difficultyLevel)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(difficultyColor(for: trail.difficultyLevel).opacity(0.2))
                            .foregroundColor(difficultyColor(for: trail.difficultyLevel))
                            .cornerRadius(4)
                        
                    }
                    .font(.caption)
                    .foregroundColor(.textSecondary)   
                }
                
                Spacer()
                
                NavigationLink {
                    TrailDetailView(trail: trail)
                        .environmentObject(userPreferences)
                        .environmentObject(dataManager)
                } label: {
                    Text("View Details")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.primaryBlue)   
                        .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(Color.surface)
        .cornerRadius(10)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // Helper function to update map region based on recommended trails
    private func updateMapRegion() {
        let trails = getMatchingTrails()
        guard !trails.isEmpty else {
            cameraPosition = .automatic
            return
        }
        
        // Calculate center point of all trails
        let avgLat = trails.map { $0.latitude }.reduce(0, +) / Double(trails.count)
        let avgLon = trails.map { $0.longitude }.reduce(0, +) / Double(trails.count)
        
        // Calculate span to show all trails
        let latitudes = trails.map { $0.latitude }
        let longitudes = trails.map { $0.longitude }
        
        let latDelta = (latitudes.max() ?? 0) - (latitudes.min() ?? 0)
        let lonDelta = (longitudes.max() ?? 0) - (longitudes.min() ?? 0)
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(latDelta * 1.5, 0.5),
            longitudeDelta: max(lonDelta * 1.5, 0.5)
        )
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
            span: span
        )
        
        cameraPosition = .region(region)
    }
    
    // Helper function for difficulty colors
    private func difficultyColor(for difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "easy":
            return .green
        case "moderate":
            return .orange
        case "hard", "difficult", "challenging":
            return .red
        default:
            return .textSecondary
        }
    }
}

// MARK: - Trail Search Result Row

struct TrailSearchResultRow: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var dataManager: DataManager

    let trail: Trail
    let isCompleted: Bool
    
    var body: some View {
        NavigationLink {
            TrailDetailView(trail: trail)
                .environmentObject(userPreferences)
                .environmentObject(dataManager)
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
                            .foregroundColor(.textPrimary)
                        
                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.primaryGreen)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Label(String(format: "%.1f mi", trail.distanceMiles), systemImage: "figure.walk")
                        Label("\(Int(trail.elevationGainFeet)) ft", systemImage: "arrow.up.right")
                    }
                    .font(.caption2)
                    .foregroundColor(.textSecondary)
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
                    .foregroundColor(.textSecondary)   
            }
            .padding(12)
            .background(Color.surface)   
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 16) // Define the rounded rectangle shape
                    .stroke(Color.borderColor1, lineWidth: 1) // Apply a stroke to the rectangle for the border
            )
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
            return .textSecondary
        }
    }
}

#Preview {
    let prefs = UserPreferences()
    let dataManager = DataManager(userPreferences: prefs)
    
    prefs.trailPreferences.helper = true
    
    return NavigationStack {
        HomeView(withTestData: true)
            .environmentObject(prefs)
            .environmentObject(dataManager)
    }
}
