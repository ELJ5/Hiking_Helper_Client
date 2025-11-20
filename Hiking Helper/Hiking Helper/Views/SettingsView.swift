//Eliana Johnson

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Trail Preferences")) {
                    Picker("Difficulty", selection: $userPreferences.trailPreferences.difficulty) {
                        Text("Easy").tag("Easy")
                        Text("Moderate").tag("Moderate")
                        Text("Hard").tag("Hard")
                        Text("Very Hard").tag("Very Hard")
                    }
                    
                    Picker("Elevation", selection: $userPreferences.trailPreferences.elevation) {
                        Text("Low (0-500 ft)").tag("Low")
                        Text("Moderate (500-1500 ft)").tag("Moderate")
                        Text("High (1500+ ft)").tag("High")
                    }
                }
                
                Section(header: Text("Distance Preference")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Minimum Distance: \(userPreferences.trailPreferences.minDistance, specifier: "%.1f") miles")
                            .font(.subheadline)
                        Slider(value: $userPreferences.trailPreferences.minDistance, in: 0...20, step: 0.5)
                            .tint(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Maximum Distance: \(userPreferences.trailPreferences.maxDistance, specifier: "%.1f") miles")
                            .font(.subheadline)
                        Slider(value: $userPreferences.trailPreferences.maxDistance, in: 0...20, step: 0.5)
                            .tint(.green)
                    }
                }
                
                Section(header: Text("Training Goals")) {
                    Picker("Current Capability", selection: $userPreferences.trailPreferences.currentCapability) {
                        Text("0-2 miles").tag("0-2 miles")
                        Text("2-4 miles").tag("2-4 miles")
                        Text("4-6 miles").tag("4-6 miles")
                        Text("6+ miles").tag("6+ miles")
                    }
                    
                    Picker("Goal Distance", selection: $userPreferences.trailPreferences.desiredDistance) {
                        Text("0-2 miles").tag("0-2 miles")
                        Text("2-4 miles").tag("2-4 miles")
                        Text("4-6 miles").tag("4-6 miles")
                        Text("6+ miles").tag("6+ miles")
                    }
                    
                    Picker("Hiking Frequency", selection: $userPreferences.trailPreferences.hikingFrequency) {
                        Text("Never have").tag("Never have")
                        Text("Once a year").tag("Once a year")
                        Text("Every 6-12 months").tag("Every 6-12 months")
                        Text("Every other month").tag("Every other month")
                        Text("Every month").tag("Every month")
                        Text("Almost weekly").tag("Almost weekly")
                    }
                }
                
                Section(header: Text("Assistance")) {
                    Toggle("Helper Mode", isOn: $userPreferences.trailPreferences.helper)
                    Text("Get detailed guidance and progressive training plans from the hiking assistant")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Location")) {
                    NavigationLink {
                        StateSelectionView(isOnboarding: false)
                            .environmentObject(userPreferences)
                            .environmentObject(dataManager)
                    } label: {
                        HStack {
                            Text("Selected States")
                            Spacer()
                            if userPreferences.trailPreferences.selectedStates.isEmpty {
                                Text("None")
                                    .foregroundColor(.secondary)
                            } else {
                                Text(userPreferences.trailPreferences.selectedStatesText)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section(header: Text("Actions")) {
                    Button("Reset to Defaults") {
                        userPreferences.reset()
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("Data")) {
                    HStack {
                        Text("Trails loaded")
                        Spacer()
                        Text("\(dataManager.allTrails.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Filtered trails")
                        Spacer()
                        Text("\(dataManager.filteredTrails.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let date = dataManager.lastLoadedDate {
                        HStack {
                            Text("Last updated")
                            Spacer()
                            Text(date, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button("Refresh Data") {
                        dataManager.refresh()
                    }
                    .disabled(dataManager.isLoading)
                    
                    if dataManager.isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let prefs = UserPreferences()
    let dataManager = DataManager(userPreferences: prefs)
    
    // Set up some sample data for preview
    prefs.trailPreferences.difficulty = "Moderate"
    prefs.trailPreferences.minDistance = 2.0
    prefs.trailPreferences.maxDistance = 8.0
    prefs.trailPreferences.elevation = "Moderate"
    prefs.trailPreferences.helper = true
    prefs.trailPreferences.currentCapability = "2-4 miles"
    prefs.trailPreferences.desiredDistance = "6+ miles"
    prefs.trailPreferences.hikingFrequency = "Every month"
    
    return SettingsView()
        .environmentObject(prefs)
        .environmentObject(dataManager)
}
