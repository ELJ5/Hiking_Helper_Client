import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        Group {
            if userPreferences.needsOnboarding {
                NavigationStack{
                    QuestionnaireView()
                        .navigationBarBackButtonHidden(true)

                }
            } else {
                NavigationStack{
                    HomeView()
                        .environmentObject(userPreferences)
                        .environmentObject(dataManager)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
        .background(.backgroundColor1)
    }
}
