//
//  ProfileView.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 10/16/25.
//

import SwiftUI
struct Trail: Identifiable{
    let id = UUID()
    let name: String
    let difficulty: String
    let durationHours:Double
}

struct ProfileView: View {
    @State private var filteredTrails: [Trail] = []
    @State private var navigateToHome = false
    @State private var navigateToSettings = false

    
    //sample data
    let allTrails = [
        Trail(name:"EasyLoop", difficulty:"Easy", durationHours:1.0),
        Trail(name:"MidLoop", difficulty:"Moderate", durationHours:2.0),
        Trail(name:"HardLoop", difficulty:"Hard", durationHours:4.0)
    ]
    
    var body: some View {
        VStack {
            HStack {
                    Button(action: {
                        navigateToHome = true
                    }){
                        Image(systemName: "star.fill") // Your icon make into profile image
                            .font(.title)
                            .foregroundColor(.green)
                            .padding(.leading, 10)
                            .padding(.top, 10)
                    }
                    .navigationDestination(isPresented: $navigateToHome) {
                        HomeView()
                    }
                Spacer()
                    Button(action: {
                        navigateToHome = true
                    }){
                        Image(systemName: "star.fill") // Your icon make into profile image
                            .font(.title)
                            .foregroundColor(.yellow)
                            .padding(.leading, 10)
                            .padding(.top, 10)
                    }
                    .navigationDestination(isPresented: $navigateToSettings) {
                        SettingsView()
                    }
            }
            
            VStack{
                Image(systemName:"globe")   //user image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width:225, height:225)
                    .padding(.top, 20)
                Text("Username1234")
                    .font(.largeTitle)
                
                VStack{
                    List(filteredTrails) { trail in
                        Text(trail.name)
                            .font(.headline)
                        Text("Difficulty: \(trail.difficulty)")
                    }
                }
                .padding()
                .onAppear(perform: filterTrails)
                
            }
        }
        

        .frame(maxHeight: .infinity, alignment: .top)
        .padding()
    }
    func filterTrails() {
        let answers = QuestionnaireManager.loadAnswers()
        let preferredDifficulty = answers["Which difficulty level do you prefer?"]
        
        if let pref = preferredDifficulty{
            filteredTrails = allTrails.filter { $0.difficulty == pref}
        } else {
            filteredTrails = allTrails
        }
    }
}

#Preview {
    ProfileView()
}
