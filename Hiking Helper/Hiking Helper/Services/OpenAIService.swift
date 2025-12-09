import Foundation

class OpenAIService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"
    
    init() {
        self.apiKey = APIConfig.openAIKey
    }
    
    // MARK: - Generate Personalized Goals
    
    func generatePersonalizedGoals(userPreferences: UserPreferences, timeframe: GoalTimeframe) async throws -> [Goal] {
        let prompt = buildGoalGenerationPrompt(from: userPreferences, timeframe: timeframe)
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "system",
                    "content": """
                    You are a professional hiking coach and goal-setting expert. Generate personalized,
                    achievable hiking goals based on the user's current capabilities and preferences.
                    Return ONLY valid JSON.
                    """
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.7
        ]
        
        let response = try await makeRequest(endpoint: "/chat/completions", body: requestBody)
        return try parseGoalsFromResponse(response, timeframe: timeframe)
    }
    
    // MARK: - Hiking Chatbot
    
    func askHikingQuestion(_ question: String, conversationHistory: [[String: String]] = []) async throws -> String {
        var messages: [[String: String]] = [
            [
                "role": "system",
                "content": """
                You are an expert hiking assistant. Provide helpful, accurate, and safe hiking advice.
                Topics include: trail recommendations, safety, gear, weather, fitness, navigation, and wildlife.
                Be concise but thorough. If something is unsafe, explain why and provide safer alternatives.
                """
            ]
        ]
        
        messages.append(contentsOf: conversationHistory)
        messages.append(["role": "user", "content": question])
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 500
        ]
        
        let response = try await makeRequest(endpoint: "/chat/completions", body: requestBody)
        
        guard let choices = response["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        return content
    }
    
    // MARK: - Private Helpers
    
    private func makeRequest(endpoint: String, body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string: baseURL + endpoint) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorDict["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OpenAIError.invalidResponse
        }
        
        return json
    }
    
    private func buildGoalGenerationPrompt(from prefs: UserPreferences, timeframe: GoalTimeframe) -> String {
        let trailPrefs = prefs.trailPreferences
        
        return """
        Generate 6-8 personalized hiking goals for a user with these characteristics:
        
        Profile:
        - Current Capability: \(trailPrefs.currentCapability)
        - Goal Distance: \(trailPrefs.desiredDistance)
        - Preferred Difficulty: \(trailPrefs.difficulty)
        - Elevation Preference: \(trailPrefs.elevation)
        - Hiking Frequency: \(trailPrefs.hikingFrequency)
        - States Interested: \(trailPrefs.selectedStates.joined(separator: ", "))
        - Completed Trails: \(trailPrefs.completedTrails.count)
        
        Timeframe: \(timeframe.rawValue)
        
        Create a balanced mix across these categories:
        - Endurance (build stamina)
        - Elevation (tackle elevation gain)
        - Distance (increase mileage)
        - Frequency (regular hiking habit)
        - Exploration (discover new trails/states)
        - Skills & Safety (improve hiking knowledge)
        
        Make goals SMART and progressively challenging but achievable.
        Vary difficulty: some easy wins, mostly moderate, few challenging.
        
        Return ONLY valid JSON in this EXACT format:
        {
            "goals": [
                {
                    "title": "Complete a 10-mile hike",
                    "description": "Build endurance by completing a single hike of 10 miles",
                    "category": "Endurance",
                    "difficulty": "Moderate"
                }
            ]
        }
        
        Categories MUST be: "Endurance", "Elevation", "Distance", "Frequency", "Exploration", or "Skills & Safety"
        Difficulty MUST be: "Easy", "Moderate", or "Challenging"
        """
    }
    
    private func parseGoalsFromResponse(_ response: [String: Any], timeframe: GoalTimeframe) throws -> [Goal] {
        guard let choices = response["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        struct GoalResponse: Codable {
            let goals: [GoalData]
        }
        
        struct GoalData: Codable {
            let title: String
            let description: String
            let category: String
            let difficulty: String
        }
        
        let data = Data(content.utf8)
        let goalResponse = try JSONDecoder().decode(GoalResponse.self, from: data)
        
        return goalResponse.goals.compactMap { goalData in
            guard let category = GoalCategory.allCases.first(where: { $0.rawValue == goalData.category }),
                  let difficulty = GoalDifficulty.allCases.first(where: { $0.rawValue == goalData.difficulty }) else {
                return nil
            }
            
            return Goal(
                title: goalData.title,
                description: goalData.description,
                category: category,
                timeframe: timeframe,
                difficulty: difficulty
            )
        }
    }
}

// MARK: - Errors

enum OpenAIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(String)
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from OpenAI"
        case .apiError(let message):
            return "OpenAI Error: \(message)"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        }
    }
}
