//
//  QuestionnaireView.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 10/18/25.
//

import Foundation
import SwiftUI

struct QuestionnaireView: View {
    @State private var questions: [Question] = []
    @State private var showResults = false
    @State private var navigateToResults = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Hiking Questionnaire")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                
                ScrollView {
                    ForEach(questions.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(questions[index].text)
                                .font(.headline)
                            
                            ForEach(questions[index].options, id: \.self) { option in
                                Button(action: {
                                    questions[index].selectedOption = option
                                    QuestionnaireManager.save(questions)
                                }) {
                                    HStack {
                                        Image(systemName: questions[index].selectedOption == option ? "circle.inset.filled" : "circle")
                                            .foregroundColor(.blue)
                                        Text(option)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .background(Color(.white))
                        .cornerRadius(10)
                        .padding(.vertical, 5)
                    }
                }
                
                Spacer()
                
                
                Button(action: submitAnswers) {
                    Text("Submit")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 10)
                .alert("Thank you!", isPresented: $showResults) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Your responses have been saved locally.")
                }
            }
            .padding()
            .onAppear(perform: loadQuestions)
            
            .navigationDestination(isPresented: $navigateToResults){
                ProfileView()
            }
        }
    }
    
    //Functions
    func loadQuestions() {
        if let saved = QuestionnaireManager.load() {
            questions = saved
        } else {
            questions = [
                Question(id: UUID(), text: "How often do you go hiking?", options: ["Daily", "Weekly", "Monthly", "Rarely"]),
                Question(id: UUID(), text: "Which difficulty level do you prefer?", options: ["Easy", "Moderate", "Hard"]),
                Question(id: UUID(), text: "How long do your hikes usually last?", options: ["<1 hour", "1–3 hours", "3–6 hours", "6+ hours"])
            ]
        }
    }
    
    func submitAnswers() {
        QuestionnaireManager.save(questions)
        showResults = true
        navigateToResults = true
        print("✅ Responses saved locally.")
    }
}

#Preview {
    QuestionnaireView()
}
