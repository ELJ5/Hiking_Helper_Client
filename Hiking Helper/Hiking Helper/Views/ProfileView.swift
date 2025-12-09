//
//  ProfileView.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 10/16/25.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Binding var isPresented: Bool
    
    @EnvironmentObject var dataManager: DataManager
    @EnvironmentObject var userPreferences: UserPreferences
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var profileUIImage: UIImage?
    
    @State private var username: String = UserDefaults.standard.string(forKey: "username") ?? "Username1234"
    @State private var isEditingUsername = false
    
    @State private var filteredTrails: [Trail] = []
    @State private var navigateToHome = false
    @State private var navigateToSettings = false
    @State private var isCompletedExpanded = false  // For dropdown
    
    var body: some View {
        VStack {
            // Header buttons
            HStack {
                Button(action: {
                    isPresented = false
                                }){
                                    Image(systemName: "house.fill")
                                        .font(.title)
                                        .foregroundColor(.primaryBlue)
                                        .padding(.leading, 10)
                                        .padding(.top, 10)
                                }
               
                Spacer()
            
//                Button(action: {
//                    navigateToSettings = true
//                }){
//                    Image(systemName: "gearshape.fill")
//                        .font(.title)
//                        .foregroundColor(.primaryBlue)
//                        .padding(.trailing, 10)
//                        .padding(.top, 10)
//                }
//                .sheet(isPresented: $navigateToSettings) {
//                    SettingsView()
//                        .environmentObject(userPreferences)
//                        .environmentObject(dataManager)
//                }
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // Profile image and username
                    VStack(spacing: 20) {
                        // Display the profile picture
                        ZStack(alignment: .bottomTrailing) {
                            if let profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.lightBlue, lineWidth: 3))
                            } else {
                                // Placeholder when no image selected
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 120, height: 120)
                                    .foregroundColor(.gray)
                            }
                            
                            // Camera button to select photo
                            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                Image(systemName: "camera.circle.fill")
                                    .font(.system(size: 35))
                                    .foregroundColor(.lightBlue)
                                    .background(Circle().fill(Color.white))
                            }
                            .offset(x: 5, y: 5)
                        }
                        
                        Text("Tap camera to change photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                profileUIImage = uiImage
                                profileImage = Image(uiImage: uiImage)
                                // Save the image
                                saveProfileImage(uiImage)
                            }
                        }
                    }
                    .onAppear {
                        // Load saved image when view appears
                        loadProfileImage()
                    }
                    
                    if isEditingUsername {
                        TextField("Username", text: $username)
                            .font(.largeTitle)
                            .bold()
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 40)
                            .onSubmit {
                                isEditingUsername = false
                                saveUsername()
                            }
                        
                        Text("Tap return when done")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        HStack(spacing: 8) {
                            Text(username)
                                .font(.largeTitle)
                                .bold()
                            
                            Button(action: {
                                isEditingUsername = true
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(.primaryBlue)
                                    .font(.title2)
                            }
                        }
                    }
                    
                    // Stats Cards
                    HStack(spacing: 15) {
                        // Completed trails card
                        StatCard(
                            icon: "checkmark.circle.fill",
                            value: "\(userPreferences.trailPreferences.completedTrails.count)",
                            label: "Trails"
                        )
                        
                        // Total miles card
                        StatCard(
                            icon: "figure.hiking",
                            value: String(format: "%.1f", totalMilesHiked),
                            label: "Miles"
                        )
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Completed Trails Dropdown
                    VStack(spacing: 0) {
                        // Dropdown header - TAP TO EXPAND
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isCompletedExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.yellow)
                                Text("Completed Trails")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(userPreferences.trailPreferences.completedTrails.count)")
                                    .foregroundColor(.secondary)
                                Image(systemName: isCompletedExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .contentShape(Rectangle())
                            
                        }
                        .buttonStyle(.plain)
                        
                        // Dropdown content
                        if isCompletedExpanded {
                            VStack(spacing: 0) {
                                if completedTrailDetails.isEmpty {
                                    Text("No trails completed yet")
                                        .foregroundColor(.secondary)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                } else {
                                    ForEach(completedTrailDetails, id: \.id) { trail in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(trail.trailName)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                Text("\(trail.distanceMiles, specifier: "%.1f") miles")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            //Add navigation part here
                                            Spacer()
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.primaryGreen)
                                        }
                                        .padding()
                                        
                                        if trail.id != completedTrailDetails.last?.id {
                                            Divider()
                                                .padding(.leading)
                                        }
                                    }
                                }
                            }
                            .background(Color(.systemGray6).opacity(0.5))
                            .cornerRadius(10)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Preferences section
                    VStack(spacing: 10) {
                        Text("Preferences")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            PreferenceRow(
                                label: "Trail Difficulty:",
                                value: userPreferences.trailPreferences.difficulty
                            )
                            
                            PreferenceRow(
                                label: "Current Capability:",
                                value: userPreferences.trailPreferences.currentCapability
                            )
                            
                            PreferenceRow(
                                label: "Goal Distance:",
                                value: userPreferences.trailPreferences.desiredDistance
                            )
                            
                            PreferenceRow(
                                label: "Elevation Preference:",
                                value: userPreferences.trailPreferences.elevation
                            )
                            
                            PreferenceRow(
                                label: "Distance Range:",
                                value: String(format: "%.1f - %.1f miles",
                                            userPreferences.trailPreferences.minDistance,
                                            userPreferences.trailPreferences.maxDistance)
                            )
                            
                            HStack {
                                Text("Helper Mode:")
                                    .padding(.leading, 20)
                                    .padding(.top, 10)
                                Spacer()
                                Text(userPreferences.trailPreferences.helper ? "Activated" : "Deactivated")
                                    .padding(.trailing, 20)
                                    .padding(.top, 10)
                                    .bold()
                                    .foregroundColor(userPreferences.trailPreferences.helper ? .primaryGreen : .gray)
                            }
                        }
                        
                        // Edit button
                        Button(action: {
                            navigateToSettings = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit Preferences")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryGreen)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .sheet(isPresented: $navigateToSettings) {
                            SettingsView()
                                .environmentObject(userPreferences)
                                .environmentObject(dataManager)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Temporary test - add some completed trails
            if userPreferences.trailPreferences.completedTrails.isEmpty {
                userPreferences.trailPreferences.completedTrails = [1001, 1002, 1003]
            }
            
            if !userPreferences.needsOnboarding {
                dataManager.loadTrailsIfNeeded()
            }
        }
    }
    
    // Computed property to get total miles hiked
    private var totalMilesHiked: Double {
        completedTrailDetails.reduce(0) { $0 + $1.distanceMiles }
    }
    
    // Computed property to get completed trail details from IDs
    private var completedTrailDetails: [Trail] {
        let completedIds = userPreferences.trailPreferences.completedTrails
        return dataManager.allTrails.filter { completedIds.contains($0.id) }
    }
    
    private func saveProfileImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: "profileImage")
        }
    }

    private func loadProfileImage() {
        if let data = UserDefaults.standard.data(forKey: "profileImage"),
           let uiImage = UIImage(data: data) {
            profileUIImage = uiImage
            profileImage = Image(uiImage: uiImage)
        }
    }
    private func saveUsername() {
        UserDefaults.standard.set(username, forKey: "username")
    }
}

// MARK: - Stat Card View
struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.primaryGreen)
            
            Text(value)
                .font(.title2)
                .bold()
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
}

// MARK: - Preference Row View
struct PreferenceRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .padding(.leading, 20)
                .padding(.top, 10)
            Spacer()
            Text(value)
                .padding(.trailing, 20)
                .padding(.top, 10)
                .bold()
        }
    }
    
}



#Preview("Profile") {
    let prefs = UserPreferences()
    let dataManager = DataManager(userPreferences: prefs)
    
    // Set up some sample preferences for preview
    prefs.trailPreferences.difficulty = "Moderate"
    prefs.trailPreferences.minDistance = 2.0
    prefs.trailPreferences.maxDistance = 5.0
    prefs.trailPreferences.elevation = "Moderate"
    prefs.trailPreferences.helper = true
    prefs.trailPreferences.currentCapability = "2-4 miles"
    prefs.trailPreferences.desiredDistance = "6+ miles"
    prefs.trailPreferences.completedTrails = [1001, 1002, 1003]  // Sample completed trail IDs
    
    return NavigationStack {
        ProfileView(isPresented: .constant(true))
            .environmentObject(prefs)
            .environmentObject(dataManager)
    }
}
