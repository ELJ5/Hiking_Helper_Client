//
//  OpenAIService.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 11/13/25.
//

import Foundation

// MARK: - OpenAI Service (Updated with Secure Config)
class OpenAIService {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init() {
        // Use the secure configuration
        self.apiKey = APIConfig.openAIKey
        
        if apiKey.isEmpty {
            print("⚠️ ERROR: OpenAI API key not configured!")
            print("Please see APIConfig.swift for setup instructions")
        }
    }
    
    func sendChatMessage(messages: [ChatMessage], userPreferences: UserPreferences) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }
        
        let systemPrompt = createSystemPrompt(from: userPreferences)
        
        // Convert messages to OpenAI format
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        
        // Add conversation history (limit to last 10 messages to save tokens)
        let recentMessages = messages.suffix(10)
        for message in recentMessages {
            apiMessages.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini", // More cost-effective model
            "messages": apiMessages,
            "temperature": 0.7,
            "max_tokens": 500,
            "top_p": 1.0,
            "frequency_penalty": 0.0,
            "presence_penalty": 0.0
        ]
        
        guard let url = URL(string: endpoint) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        // Handle different HTTP status codes
        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw OpenAIError.authenticationError
        case 429:
            throw OpenAIError.rateLimitError
        case 500...599:
            throw OpenAIError.serverError
        default:
            throw OpenAIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Parse the response
        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let messageContent = openAIResponse.choices.first?.message.content else {
            throw OpenAIError.noContent
        }
        
        return messageContent
    }
    
    private func createSystemPrompt(from userPreferences: UserPreferences) -> String {
        let prefs = userPreferences.trailPreferences
        
        var prompt = """
        You are a knowledgeable and encouraging hiking assistant specializing in trail recommendations and training plans.
        Your role is to help users find suitable trails, create progressive training plans, and achieve their hiking goals.
        
        Be:
        - Friendly and supportive
        - Specific in recommendations
        - Safety-conscious
        - Encouraging but realistic
        
        User Profile:
        """
        
        // Add user's hiking experience
        if !prefs.hikingFrequency.isEmpty {
            prompt += "\n- Hiking frequency: \(prefs.hikingFrequency)"
        }
        
        // Add current capability
        if !prefs.currentCapability.isEmpty {
            prompt += "\n- Current comfortable distance: \(prefs.currentCapability)"
        }
        
        // Add desired distance
        if !prefs.desiredDistance.isEmpty {
            prompt += "\n- Goal distance: \(prefs.desiredDistance)"
            
            // Calculate if they need progression
            if prefs.currentCapability != prefs.desiredDistance {
                prompt += " (wants to progress from current level)"
            }
        }
        
        // Add difficulty preference
        if !prefs.difficulty.isEmpty {
            prompt += "\n- Preferred difficulty: \(prefs.difficulty)"
        }
        
        // Add elevation preference
        if !prefs.elevation.isEmpty {
            prompt += "\n- Preferred elevation gain: \(prefs.elevation)"
        }
        
        // Add location
        if let location = prefs.location {
            prompt += "\n- Location: \(location)"
        }
        
        // Add travel radius
        if !prefs.travelRadius.isEmpty {
            prompt += "\n- Willing to travel: \(prefs.travelRadius)"
        }
        
        // Add helper mode context
        if prefs.helper {
            prompt += """
            
            
            IMPORTANT: This user wants detailed guidance and support.
            Provide:
            - Progressive training suggestions with specific weekly plans
            - Safety tips appropriate for their level
            - Encouragement and milestone celebrations
            - Step-by-step explanations
            - Preparation checklists when suggesting new trails
            """
        } else {
            prompt += """
            
            
            This user is experienced and wants concise recommendations without excessive guidance.
            """
        }
        
        prompt += """
        
        
        GUIDELINES FOR RESPONSES:
        
        Trail Recommendations:
        • Match their stated preferences (difficulty, distance, elevation)
        • If suggesting progression, ensure it's gradual (10-20% increase max)
        • Include: trail name, distance, elevation gain, difficulty rating
        • Mention key features: views, water sources, terrain, crowds, best season
        • Provide practical details: parking, permits, cell service
        
        Training Plans:
        • Start from their current capability
        • Progress gradually with specific weekly goals
        • Include rest days (at least 1-2 per week)
        • Add cross-training suggestions (strength, flexibility)
        • Set realistic timeframes (e.g., "12 weeks to go from 2 miles to 6 miles")
        • Emphasize injury prevention and listening to their body
        
        General Advice:
        • Gear: Only suggest essentials for their level
        • Safety: Always mention water, sun protection, navigation, and telling someone their plans
        • Weather: Remind them to check conditions before hiking
        • Fitness: Cardio + leg strength + core stability
        
        Keep responses conversational but informative. Use bullet points for lists. Be encouraging!
        """
        
        return prompt
    }
    
}

// MARK: - OpenAI Response Models
struct OpenAIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage?
    
    struct Choice: Codable {
        let index: Int
        let message: Message
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
        
        struct Message: Codable {
            let role: String
            let content: String
        }
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// MARK: - Errors
enum OpenAIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case noContent
    case networkError(Error)
    case authenticationError
    case rateLimitError
    case serverError
    case missingAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "Server error: \(statusCode)"
        case .noContent:
            return "No content in response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationError:
            return "Authentication failed. Please check your API key."
        case .rateLimitError:
            return "Rate limit exceeded. Please try again later."
        case .serverError:
            return "OpenAI server error. Please try again."
        case .missingAPIKey:
            return "OpenAI API key not configured. Please see APIConfig.swift for setup instructions."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationError:
            return "Verify your OpenAI API key is correct"
        case .rateLimitError:
            return "Wait a few minutes before trying again"
        case .serverError:
            return "Check OpenAI status at status.openai.com"
        case .missingAPIKey:
            return "Configure your API key using one of the methods in APIConfig.swift"
        default:
            return nil
        }
    }
}
