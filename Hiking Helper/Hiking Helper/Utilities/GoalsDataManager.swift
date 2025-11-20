import Foundation
import Combine

class GoalDataManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var goals: [Goal] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Private Properties
    private let userDefaultsKey = "savedHikingGoals"
    private let fileManager = FileManager.default
    
    // MARK: - Computed Properties
    var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }
    
    var pendingGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }
    
    var completionPercentage: Double {
        guard !goals.isEmpty else { return 0 }
        return Double(completedGoals.count) / Double(goals.count) * 100
    }
    
    var goalsByCategory: [GoalCategory: [Goal]] {
        Dictionary(grouping: goals, by: { $0.category })
    }
    
    // MARK: - Initialization
    init() {
        loadGoals()
    }
    
    /// Initialize with test data for previews
    init(withTestData: Bool) {
        if withTestData {
            self.goals = Goal.sampleGoals
        } else {
            loadGoals()
        }
    }
    
    // MARK: - AI Goal Generation
    
    /// Generate goals based on user's trail preferences
    func generateGoals(from preferences: TrailPreferences, timeframe: GoalTimeframe = .weekly) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        let prompt = buildPrompt(from: preferences, timeframe: timeframe)
        
        do {
            let generatedGoals = try await callAI(with: prompt, preferences: preferences, timeframe: timeframe)
            
            await MainActor.run {
                self.goals = generatedGoals
                self.saveGoals()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate goals: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func buildPrompt(from preferences: TrailPreferences, timeframe: GoalTimeframe) -> String {
        let currentLevel = preferences.isBeginner ? "beginner" : "intermediate to advanced"
        let progressGoal = preferences.wantsToProgress ? "wants to progress from \(preferences.currentCapability) to \(preferences.desiredDistance)" : "wants to maintain current fitness"
        
        return """
        You are a hiking coach and goal-setting assistant. Based on the hiker's preferences, generate 5 specific, actionable hiking goals.

        Hiker Profile:
        - Experience Level: \(currentLevel)
        - Hiking Frequency: \(preferences.hikingFrequency)
        - Current Capability: \(preferences.currentCapability)
        - Desired Distance: \(preferences.desiredDistance)
        - Preferred Difficulty: \(preferences.difficulty)
        - Elevation Preference: \(preferences.elevation)
        - Distance Range: \(preferences.distanceRangeText)
        - Travel Radius: \(preferences.travelRadius)
        - Location: \(preferences.location ?? "Not specified")
        - Progress Goal: \(progressGoal)
        - Trails Completed: \(preferences.completedTrailCount)
        - Uses Helper Mode: \(preferences.helper)

        Generate 5 hiking goals that are:
        - Specific and measurable
        - Appropriate for the \(timeframe.rawValue.lowercased()) timeframe
        - Aligned with the \(preferences.difficulty) difficulty level
        - Help the hiker progress toward their desired distance of \(preferences.desiredDistance)
        - Consider their current capability of \(preferences.currentCapability)

        Categories to consider: Endurance, Elevation, Distance, Frequency, Exploration, Skills & Safety

        Respond ONLY with a valid JSON array of objects, each with these fields:
        - "id": number (1-5)
        - "title": string (goal title)
        - "description": string (brief description)
        - "category": string (one of: "Endurance", "Elevation", "Distance", "Frequency", "Exploration", "Skills & Safety")

        Example format:
        [
          {"id": 1, "title": "Goal title", "description": "Brief description", "category": "Distance"}
        ]

        DO NOT include any text outside the JSON array. Your entire response must be valid JSON.
        """
    }
    
    private func callAI(with prompt: String, preferences: TrailPreferences, timeframe: GoalTimeframe) async throws -> [Goal] {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw GoalGenerationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Note: API key should be handled securely - this is a placeholder
        // request.setValue("Bearer YOUR_API_KEY", forHTTPHeaderField: "Authorization")
        
        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1000,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GoalGenerationError.apiError
        }
        
        // Parse the API response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw GoalGenerationError.parsingError
        }
        
        // Clean up and parse the goals JSON
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let goalsData = cleanedText.data(using: .utf8) else {
            throw GoalGenerationError.parsingError
        }
        
        let generatedGoals = try JSONDecoder().decode([GeneratedGoal].self, from: goalsData)
        
        // Convert to Goal objects
        let difficulty = mapDifficulty(from: preferences.difficulty)
        
        return generatedGoals.map { generated in
            Goal(
                title: generated.title,
                description: generated.description,
                category: mapCategory(from: generated.category),
                timeframe: timeframe,
                difficulty: difficulty
            )
        }
    }
    
    private func mapCategory(from string: String) -> GoalCategory {
        switch string.lowercased() {
        case "endurance": return .endurance
        case "elevation": return .elevation
        case "distance": return .distance
        case "frequency": return .frequency
        case "exploration": return .exploration
        case "skills & safety", "skills": return .skills
        default: return .distance
        }
    }
    
    private func mapDifficulty(from string: String) -> GoalDifficulty {
        switch string.lowercased() {
        case "easy": return .easy
        case "moderate": return .moderate
        case "challenging", "hard", "difficult": return .challenging
        default: return .moderate
        }
    }
    
    // MARK: - CRUD Operations
    
    func addGoal(_ goal: Goal) {
        goals.append(goal)
        saveGoals()
    }
    
    func addGoals(_ newGoals: [Goal]) {
        goals.append(contentsOf: newGoals)
        saveGoals()
    }
    
    func updateGoal(_ goal: Goal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            saveGoals()
        }
    }
    
    func deleteGoal(id: UUID) {
        goals.removeAll { $0.id == id }
        saveGoals()
    }
    
    func deleteGoals(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
        saveGoals()
    }
    
    func toggleGoalCompletion(id: UUID) {
        if let index = goals.firstIndex(where: { $0.id == id }) {
            goals[index].toggleCompletion()
            saveGoals()
        }
    }
    
    func clearAllGoals() {
        goals.removeAll()
        saveGoals()
    }
    
    func replaceAllGoals(with newGoals: [Goal]) {
        goals = newGoals
        saveGoals()
    }
    
    // MARK: - Filtering & Sorting
    
    func goals(for category: GoalCategory) -> [Goal] {
        goals.filter { $0.category == category }
    }
    
    func goals(for timeframe: GoalTimeframe) -> [Goal] {
        goals.filter { $0.timeframe == timeframe }
    }
    
    func goals(completed: Bool) -> [Goal] {
        goals.filter { $0.isCompleted == completed }
    }
    
    func goalsSortedByDate(ascending: Bool = false) -> [Goal] {
        goals.sorted {
            ascending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt
        }
    }
    
    func goalsSortedByCompletion() -> [Goal] {
        goals.sorted { !$0.isCompleted && $1.isCompleted }
    }
    
    // MARK: - Persistence
    
    private func saveGoals() {
        do {
            let encoded = try JSONEncoder().encode(goals)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to save goals: \(error.localizedDescription)"
        }
    }
    
    private func loadGoals() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            goals = []
            return
        }
        
        do {
            goals = try JSONDecoder().decode([Goal].self, from: data)
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load goals: \(error.localizedDescription)"
            goals = []
        }
    }
    
    // MARK: - Statistics
    
    func getStatistics() -> GoalStatistics {
        GoalStatistics(
            totalGoals: goals.count,
            completedGoals: completedGoals.count,
            pendingGoals: pendingGoals.count,
            completionRate: completionPercentage,
            goalsByCategory: goalsByCategory.mapValues { $0.count },
            recentlyCompleted: completedGoals
                .sorted { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) }
                .prefix(5)
                .map { $0 }
        )
    }
}

// MARK: - Supporting Types

struct GeneratedGoal: Codable {
    let id: Int
    let title: String
    let description: String
    let category: String
}

struct GoalStatistics {
    let totalGoals: Int
    let completedGoals: Int
    let pendingGoals: Int
    let completionRate: Double
    let goalsByCategory: [GoalCategory: Int]
    let recentlyCompleted: [Goal]
}

enum GoalGenerationError: LocalizedError {
    case invalidURL
    case apiError
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .apiError: return "API request failed"
        case .parsingError: return "Failed to parse response"
        }
    }
}

// MARK: - Sample Goals for Previews

extension Goal {
    static let sampleGoals: [Goal] = [
        Goal(
            title: "Complete a 3-mile trail",
            description: "Find and complete a trail between 2.5-3.5 miles to build your base endurance.",
            category: .distance,
            timeframe: .weekly,
            difficulty: .moderate,
            isCompleted: false,
            createdAt: Date()
        ),
        Goal(
            title: "Hike twice this week",
            description: "Get out on the trail at least twice to build consistency in your hiking routine.",
            category: .frequency,
            timeframe: .weekly,
            difficulty: .easy,
            isCompleted: true,
            completedAt: Date().addingTimeInterval(-86400),
            createdAt: Date().addingTimeInterval(-172800)
        ),
        Goal(
            title: "Try a trail with 300ft elevation gain",
            description: "Challenge yourself with moderate elevation to prepare for more difficult hikes.",
            category: .elevation,
            timeframe: .weekly,
            difficulty: .moderate,
            isCompleted: false,
            createdAt: Date().addingTimeInterval(-86400)
        ),
        Goal(
            title: "Explore a new trail system",
            description: "Visit a trail you've never hiked before to expand your hiking knowledge and experience.",
            category: .exploration,
            timeframe: .weekly,
            difficulty: .easy,
            isCompleted: true,
            completedAt: Date().addingTimeInterval(-43200),
            createdAt: Date().addingTimeInterval(-259200)
        ),
        Goal(
            title: "Practice using trail markers",
            description: "Learn to read and follow blazes, cairns, and trail signs for safer navigation.",
            category: .skills,
            timeframe: .weekly,
            difficulty: .easy,
            isCompleted: false,
            createdAt: Date().addingTimeInterval(-172800)
        )
    ]
}
