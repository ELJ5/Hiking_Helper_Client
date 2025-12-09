import Foundation
import SwiftUI

struct QuestionnaireView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var dataManager: DataManager
    
    @State private var questions: [Question] = []
    @State private var showResults = false
    @State private var navigateToStateSelection = false
    @State private var currentQuestion = 0
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Image at top from Assets
                Image("HH")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 20) {
                        if currentQuestion == 0 {
                            Text("Welcome to Hiking Helper")
                                .font(.largeTitle)
                                .bold()
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 10)
                                .transition(.opacity.combined(with: .scale))
                        }
                        
                        if !questions.isEmpty {
                            // Progress indicator
                            ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                                .tint(.darkGreen)
                                .padding(.horizontal, 30)
                            
                            // Current question - Centered
                            if currentQuestion < questions.count {
                                let question = questions[currentQuestion]
                                
                                VStack(spacing: 15) {
                                    Text("Question \(currentQuestion + 1) of \(questions.count)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(question.text)
                                        .font(.headline)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                    
                                    // Handle state selection question
                                    if question.preferenceKey == "stateSelection" {
                                        VStack(spacing: 12) {
                                            // Show currently selected states
                                            if !userPreferences.trailPreferences.selectedStates.isEmpty {
                                                HStack {
                                                    Text("Selected:")
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                    Text(userPreferences.trailPreferences.selectedStatesText)
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.primaryGreen)
                                                }
                                                .padding(.vertical, 4)
                                            }
                                            
                                            Button(action: {
                                                navigateToStateSelection = true
                                            }) {
                                                HStack {
                                                    Image(systemName: "map.fill")
                                                    Text(userPreferences.trailPreferences.selectedStates.isEmpty
                                                         ? "Select States"
                                                         : "Change Selection")
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                            }
                                            
                                            if !userPreferences.trailPreferences.selectedStates.isEmpty {
                                                Button(action: {
                                                    questions[currentQuestion].selectedOption = userPreferences.trailPreferences.selectedStatesText
                                                    QuestionnaireManager.save(questions)
                                                    
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                        withAnimation {
                                                            advanceToNextQuestion()
                                                        }
                                                    }
                                                }) {
                                                    Text("Continue with \(userPreferences.trailPreferences.selectedStates.count) state\(userPreferences.trailPreferences.selectedStates.count == 1 ? "" : "s")")
                                                        .frame(maxWidth: .infinity)
                                                        .padding()
                                                        .background(Color.primaryBlue)
                                                        .foregroundColor(.white)
                                                        .cornerRadius(10)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    } else {
                                        // Radio button options - Centered
                                        VStack(spacing: 12) {
                                            ForEach(question.options, id: \.self) { option in
                                                Button(action: {
                                                    selectOption(option, for: currentQuestion)
                                                }) {
                                                    HStack {
                                                        Image(systemName: question.selectedOption == option ? "circle.inset.filled" : "circle")
                                                            .foregroundColor(.darkBlue)
                                                        Text(option)
                                                            .foregroundColor(.primary)
                                                        Spacer()
                                                    }
                                                    .padding()
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(question.selectedOption == option ? Color.green.opacity(0.1) : Color(.systemGray6))
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(question.selectedOption == option ? Color.green : Color.clear, lineWidth: 2)
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 30)
                                    }
                                }
                                .padding(.vertical, 20)
                                .background(Color(.systemBackground))
                                .cornerRadius(15)
                                .shadow(color: .gray.opacity(0.2), radius: 5)
                                .padding(.horizontal, 20)
                            }
                        } else {
                            // Show loading state
                            ProgressView("Loading questions...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .onAppear(perform: loadQuestions)
            .navigationDestination(isPresented: $navigateToStateSelection) {
                StateSelectionView(isOnboarding: true) {
                    navigateToStateSelection = false
                    
                    if !userPreferences.trailPreferences.selectedStates.isEmpty {
                        questions[currentQuestion].selectedOption = userPreferences.trailPreferences.selectedStatesText
                        QuestionnaireManager.save(questions)
                    }
                }
                .environmentObject(userPreferences)
                .environmentObject(dataManager).navigationBarBackButtonHidden(true)
            }
        }
    }

    // MARK: - Functions
    
    func loadQuestions() {
        if let saved = QuestionnaireManager.load() {
            questions = saved
        } else {
            questions = [
                Question(
                    text: "How can Hiking Helper assist you?",
                    options: [
                        "I'm new to hiking and need the basics",
                        "I have a dream hike I want to do",
                        "Just want help finding trails"
                    ],
                    preferenceKey: "helperEnabled"
                ),
                
                Question(
                    text: "How often do you hike?",
                    options: [
                        "Never have",
                        "Once a year",
                        "Every 6-12 months",
                        "Every other month",
                        "Every month",
                        "Almost weekly"
                    ],
                    preferenceKey: "hikingFrequency"
                ),
                
                Question(
                    text: "How far do you want to hike eventually?",
                    options: ["0-2 miles", "2-4 miles", "4-6 miles", "6+ miles"],
                    preferenceKey: "desiredDistance"
                ),
                
                Question(
                    text: "How far can you comfortably hike right now?",
                    options: ["0-2 miles", "2-4 miles", "4-6 miles", "6+ miles"],
                    preferenceKey: "currentCapability"
                ),
                
                Question(
                    text: "What difficulty level are you comfortable with?",
                    options: ["Easy", "Moderate", "Hard", "Very Hard"],
                    preferenceKey: "difficulty"
                ),
                
                Question(
                    text: "What elevation gain are you looking for?",
                    options: ["Low (0-500 ft)", "Moderate (500-1500 ft)", "High (1500+ ft)"],
                    preferenceKey: "elevation"
                ),
                
                Question(
                    text: "Which states would you like to explore trails in?",
                    options: [],
                    preferenceKey: "stateSelection"
                ),
                
                Question(
                    text: "Ready to start your hiking journey?",
                    options: ["Yes, let's go!", "Can't wait!"],
                    preferenceKey: "completion"
                )
            ]
        }
    }
    
    func selectOption(_ option: String, for questionIndex: Int) {
        questions[questionIndex].selectedOption = option
        QuestionnaireManager.save(questions)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                advanceToNextQuestion()
            }
        }
    }
    
    func advanceToNextQuestion() {
        if currentQuestion < questions.count - 1 {
            currentQuestion += 1
        } else {
            submitAnswers()
        }
    }
    
    func submitAnswers() {
        QuestionnaireManager.save(questions)
        updateUserPreferences()
        
        var prefs = userPreferences.trailPreferences
        prefs.hasCompletedOnboarding = true
        userPreferences.trailPreferences = prefs
        
        dataManager.loadTrailsIfNeeded()
        
        print("✅ Preferences saved: \(userPreferences.trailPreferences)")
        print("✅ Selected states: \(userPreferences.trailPreferences.selectedStates)")
        print("✅ Onboarding complete: \(userPreferences.trailPreferences.hasCompletedOnboarding)")
    }
    
    func updateUserPreferences() {
        var prefs = userPreferences.trailPreferences
        
        for question in questions {
            guard let answer = question.selectedOption else { continue }
            
            switch question.preferenceKey {
            case "helperEnabled":
                prefs.helper = (answer != "Just want help finding trails")
                
            case "hikingFrequency":
                prefs.hikingFrequency = answer
                
            case "desiredDistance":
                prefs.desiredDistance = answer
                prefs.maxDistance = parseDistance(answer)
                
            case "currentCapability":
                prefs.currentCapability = answer
                prefs.minDistance = parseMinDistance(answer)
                
            case "difficulty":
                prefs.difficulty = answer
                
            case "elevation":
                prefs.elevation = answer.components(separatedBy: " (").first ?? answer
                
            case "stateSelection":
                break
                
            case "travelRadius":
                prefs.travelRadius = answer
                
            default:
                break
            }
        }
        
        userPreferences.trailPreferences = prefs
    }
    
    func parseDistance(_ distanceString: String) -> Double {
        switch distanceString {
        case "0-2 miles": return 2.0
        case "2-4 miles": return 4.0
        case "4-6 miles": return 6.0
        case "6+ miles": return 10.0
        default: return 3.0
        }
    }
    
    func parseMinDistance(_ distanceString: String) -> Double {
        switch distanceString {
        case "0-2 miles": return 0.0
        case "2-4 miles": return 2.0
        case "4-6 miles": return 4.0
        case "6+ miles": return 6.0
        default: return 0.0
        }
    }
}

#Preview {
    let prefs = UserPreferences()
    let dataManager = DataManager(userPreferences: prefs)
    
    let view = QuestionnaireView()
    
    return view
        .environmentObject(prefs)
        .environmentObject(dataManager)
}
