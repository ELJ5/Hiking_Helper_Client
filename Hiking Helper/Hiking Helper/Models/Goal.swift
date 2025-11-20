//
//  Goal.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 11/19/25.
//

//import Foundation
//struct Goal: Identifiable, Codable {
//    let id: Int
//    let description: String
//    let achieved: Bool
//}

import Foundation

struct Goal: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var description: String
    var category: GoalCategory
    var timeframe: GoalTimeframe
    var difficulty: GoalDifficulty
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: GoalCategory = .endurance,
        timeframe: GoalTimeframe = .weekly,
        difficulty: GoalDifficulty = .moderate,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.timeframe = timeframe
        self.difficulty = difficulty
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
    }
    
    mutating func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
    }
}

// Hiking-focused goal categories
enum GoalCategory: String, Codable, CaseIterable {
    case endurance = "Endurance"
    case elevation = "Elevation"
    case distance = "Distance"
    case frequency = "Frequency"
    case exploration = "Exploration"
    case skills = "Skills & Safety"
    
    var iconName: String {
        switch self {
        case .endurance: return "heart.fill"
        case .elevation: return "mountain.2.fill"
        case .distance: return "figure.walk"
        case .frequency: return "calendar"
        case .exploration: return "map.fill"
        case .skills: return "checkmark.shield.fill"
        }
    }
    
    var color: String {
        switch self {
        case .endurance: return "red"
        case .elevation: return "purple"
        case .distance: return "blue"
        case .frequency: return "green"
        case .exploration: return "orange"
        case .skills: return "teal"
        }
    }
}

enum GoalTimeframe: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

enum GoalDifficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case moderate = "Moderate"
    case challenging = "Challenging"
    
    var description: String {
        switch self {
        case .easy: return "Quick wins"
        case .moderate: return "Balanced challenge"
        case .challenging: return "Push yourself"
        }
    }
}
