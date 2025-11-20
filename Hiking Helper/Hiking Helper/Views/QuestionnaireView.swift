import Foundation
import SwiftUI

struct QuestionnaireView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var dataManager: DataManager
    
    @State private var questions: [Question] = []
    @State private var showResults = false
    @State private var navigateToResults = false
    @State private var currentQuestion = 0
    @State private var showLocationInput = false
    @State private var cityInput = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Hiking Questionnaire")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                
                if !questions.isEmpty {
                    // Progress indicator
                    ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                        .tint(.green)
                    
                    // Current question
                    if currentQuestion < questions.count {
                        let question = questions[currentQuestion]
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Question \(currentQuestion + 1) of \(questions.count)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(question.text)
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                            
                            // Handle text input for city
                            if question.preferenceKey == "location" && question.selectedOption == "input" {
                                VStack(spacing: 12) {
                                    TextField("Enter city name", text: $cityInput)
                                        .textFieldStyle(.roundedBorder)
                                        .padding(.vertical, 8)
                                        .focused($isTextFieldFocused)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            submitCityInput()
                                        }
                                    
                                    Button(action: submitCityInput) {
                                        Text("Continue")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(!cityInput.trimmingCharacters(in: .whitespaces).isEmpty ? Color.blue : Color.gray)
                                            .foregroundColor(.white)
                                            .cornerRadius(10)
                                    }
                                    .disabled(cityInput.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                            } else {
                                // Radio button options
                                ForEach(question.options, id: \.self) { option in
                                    Button(action: {
                                        selectOption(option, for: currentQuestion)
                                    }) {
                                        HStack {
                                            Image(systemName: question.selectedOption == option ? "circle.inset.filled" : "circle")
                                                .foregroundColor(.blue)
                                            Text(option)
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                } else {
                    // Show loading state
                    ProgressView("Loading questions...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
            }
            .padding()
            .onAppear(perform: loadQuestions)
            .navigationDestination(isPresented: $navigateToResults) {
                HomeView()
            }
        }
    }

    // MARK: - Functions
    
    func loadQuestions() {
        // Load saved progress if exists
        if let saved = QuestionnaireManager.load() {
            questions = saved
        } else {
            // Initialize questions with preference keys
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
                    text: "Can we use your location to find nearby trails?",
                    options: ["Yes, use my location", "No, I'll enter a city"],
                    preferenceKey: "locationPermission"
                ),
                
                Question(
                    text: "Enter your city or preferred area:",
                    options: ["input"],
                    preferenceKey: "location"
                ),
                
                Question(
                    text: "How far are you willing to travel for a trail?",
                    options: ["<60 miles", "60-100 miles", "100-125 miles", "125-250 miles", "250+ miles"],
                    preferenceKey: "travelRadius"
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
        
        // Auto-advance after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                advanceToNextQuestion()
            }
        }
    }
    
    func submitCityInput() {
        let trimmedInput = cityInput.trimmingCharacters(in: .whitespaces)
        guard !trimmedInput.isEmpty else { return }
        
        questions[currentQuestion].selectedOption = trimmedInput
        QuestionnaireManager.save(questions)
        
        // Dismiss keyboard
        isTextFieldFocused = false
        
        // Advance to next question
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
        // Save final state
        QuestionnaireManager.save(questions)
        
        // Update user preferences
        updateUserPreferences()
        
        // Mark onboarding as complete
        var prefs = userPreferences.trailPreferences
        prefs.hasCompletedOnboarding = true
        userPreferences.trailPreferences = prefs
        
        // Load hiking data
        dataManager.loadTrailsIfNeeded()
        
        // Navigate to home
        navigateToResults = true
        
        print("✅ Preferences saved: \(userPreferences.trailPreferences)")
    }
    
    func updateUserPreferences() {
        var prefs = userPreferences.trailPreferences
        
        // Map each question to preference property
        for question in questions {
            guard let answer = question.selectedOption else { continue }
            
            switch question.preferenceKey {
            case "helperEnabled":
                prefs.helper = (answer != "Just want help finding trails")
                
            case "hikingFrequency":
                prefs.hikingFrequency = answer
                
            case "desiredDistance":
                prefs.desiredDistance = answer
                // Also update max distance for filtering
                prefs.maxDistance = parseDistance(answer)
                
            case "currentCapability":
                prefs.currentCapability = answer
                // Update min distance
                prefs.minDistance = parseMinDistance(answer)
                
            case "difficulty":
                prefs.difficulty = answer
                
            case "elevation":
                prefs.elevation = answer.components(separatedBy: " (").first ?? answer
                
                //Fix this here:
                //maybe option of states to select
            case "locationPermission":
                break
                
            case "location":
                prefs.location = answer == "input" ? nil : answer
                
            case "travelRadius":
                prefs.travelRadius = answer
                
            default:
                break
            }
        }
        
        // Save updated preferences
        userPreferences.trailPreferences = prefs
    }
    
    // Helper functions to convert distance strings to double
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
    
    // Initialize with mock data to avoid crashes
    let view = QuestionnaireView()
    
    return view
        .environmentObject(prefs)
        .environmentObject(dataManager)
        .onAppear {
            // Prevent any persistence calls in preview
        }
}
