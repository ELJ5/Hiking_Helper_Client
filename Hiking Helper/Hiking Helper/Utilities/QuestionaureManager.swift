//
//  QuestionaureManager.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 10/18/25.
//

import Foundation

struct Question: Identifiable, Codable {
    let id: UUID
    let text: String
    let options: [String]
    var selectedOption: String?
}

struct QuestionnaireManager {
    static let storageKey = "SavedQuestionnaireResponses"
    // Save full list of questions + answers
    static func save(_ questions: [Question]) {
        if let encoded = try? JSONEncoder().encode(questions) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    // Load all saved questions (or nil if none saved)
    static func load() -> [Question]? {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Question].self, from: data) {
            return decoded
        }
        return nil
    }
    // Load as a dictionary of [QuestionText: Answer] for filtering
    static func loadAnswers() -> [String: String] {
        guard let questions = load() else { return [:] }
        var answers: [String: String] = [:]
        for q in questions {
            if let answer = q.selectedOption {
                answers[q.text] = answer
            }
        }
        return answers
    }
    // Optional: clear all stored answers
    static func reset() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
