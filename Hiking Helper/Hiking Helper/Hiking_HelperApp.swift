import SwiftUI

@main
struct HikingHelperApp: App {
    @StateObject private var userPreferences = UserPreferences()
    @StateObject private var dataManager: DataManager
    
    
    init() {
        let prefs = UserPreferences()
        _userPreferences = StateObject(wrappedValue: prefs)
        _dataManager = StateObject(wrappedValue: DataManager(userPreferences: prefs))
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack{
            ContentView()
                
                .environmentObject(userPreferences)
                .environmentObject(dataManager)
                .onAppear {

                    // Debug: List all JSON files in bundle
                    if let resourcePath = Bundle.main.resourcePath {
                        do {
                            let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                            let jsonFiles = contents.filter { $0.hasSuffix(".json") }
                            print("📦 JSON files in bundle: \(jsonFiles)")
                        } catch {
                            print("❌ Could not list bundle: \(error)")
                        }
                    }

                    if !userPreferences.needsOnboarding {
                        dataManager.loadTrailsIfNeeded()
                    }
                }
        }
        }
    }
}
