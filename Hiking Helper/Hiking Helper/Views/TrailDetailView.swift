//
//  TrailDetailView.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 11/20/25.
//

import SwiftUI
import MapKit

struct TrailDetailView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var dataManager: DataManager

    let trail: Trail
    
    @State private var cameraPosition: MapCameraPosition
    @Environment(\.dismiss) var dismiss
    
    @State private var navigateToHome = false
    
    init(trail: Trail) {
        self.trail = trail
        self._cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: trail.latitude, longitude: trail.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )))
    }
    
    var isCompleted: Bool {
        userPreferences.trailPreferences.isTrailCompleted(trail.id)
    }
    
    var body: some View {
        ScrollView {

            VStack(spacing: 0) {
                // Map Header
                ZStack(alignment: .topTrailing) {
                    Map(position: $cameraPosition) {
                        Marker(trail.trailName, coordinate: CLLocationCoordinate2D(
                            latitude: trail.latitude,
                            longitude: trail.longitude
                        ))
                        .tint(.primaryGreen)
                    }
                    .frame(height: 250)
                    .allowsHitTesting(false)
                    
                    // Completion Badge
                    if isCompleted {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Completed")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.primaryGreen)
                        .cornerRadius(20)
                        .padding(12)
                    }
                }
                
                // Trail Information
                VStack(alignment: .leading, spacing: 20) {
                    // Title and Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text(trail.trailName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text(trail.state)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Replace the Quick Stats section with this:

                    // Quick Stats
                    VStack(spacing: 12) {
                        // Top row: Distance and Elevation
                        HStack(spacing: 12) {
                            StatBox(
                                icon: "figure.walk",
                                value: String(format: "%.1f mi", trail.distanceMiles),
                                color: .primaryBlue
                            )
                            
                            StatBox(
                                icon: "arrow.up.right",
                                value: "\(Int(trail.elevationGainFeet)) ft",
                                color: .primaryBlue
                            )
                        }
                        
                        // Bottom row: Difficulty (full width)
                        StatBox(
                            icon: "gauge.medium",
                            value: trail.difficultyLevel,
                            color: difficultyColor
                        )
                    }
                    
                    Divider()
                    
                    // Rating
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", trail.userRating))
                            .font(.headline)
                        Text("User Rating")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About This Trail")
                            .font(.headline)
                        
                        Text(trail.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Terrain Types
                    if !trail.terrainTypes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Terrain Types")
                                .font(.headline)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(trail.terrainTypes, id: \.self) { terrain in
                                    Text(terrain)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.lightGreen.opacity(0.2))
                                        .foregroundColor(.darkGreen)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        
                        Divider()
                    }
                    
                    // Location Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Coordinates")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(trail.latitude, specifier: "%.4f"), \(trail.longitude, specifier: "%.4f")")
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Complete/Uncomplete Button
                        Button(action: {
                            userPreferences.toggleTrailCompletion(trail.id)
                        }) {
                            HStack {
                                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                Text(isCompleted ? "Mark as Incomplete" : "Mark as Complete")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isCompleted ? Color.darkBlue : Color.primaryGreen)
                            .cornerRadius(12)
                        }
                        
                        // Get Directions Button
                        Button(action: {
                            openInMaps()
                        }) {
                            HStack {
                                Image(systemName: "map")
                                Text("Get Directions")
                            }
                            .font(.headline)
                            .foregroundColor(.primaryBlue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryBlue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Share trail
                    shareTrail()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
                .foregroundColor(.primaryGreen)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var difficultyColor: Color {
        switch trail.difficultyLevel.lowercased() {
        case "easy":
            return .green
        case "moderate":
            return .orange
        case "hard", "very hard":
            return .red
        default:
            return .secondary
        }
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: trail.latitude, longitude: trail.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = trail.trailName
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
    
    private func shareTrail() {
        let shareText = """
        Check out this trail: \(trail.trailName)
        Location: \(trail.state)
        Distance: \(String(format: "%.1f", trail.distanceMiles)) miles
        Difficulty: \(trail.difficultyLevel)
        """
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}



// MARK: - Stat Box Component

struct StatBox: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct TrailDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTrail = Trail(
            id: 1001,
            trailName: "Palmetto Trail",
            state: "SC",
            latitude: 34.8526,
            longitude: -82.3940,
            distanceMiles: 12.5,
            elevationGainFeet: 1200,
            difficultyLevel: "Moderate",
            terrainTypes: ["Rocky", "Forest"],
            description: "Beautiful forested trail with scenic overlooks and moderate elevation changes.",
            userRating: 4.5,
            completed: false
        )
        
        NavigationStack {
            let prefs = UserPreferences()
            let datamanager = DataManager(userPreferences: prefs)
            
            TrailDetailView(trail: sampleTrail)
                .environmentObject(prefs)
                .environmentObject(datamanager)
        }
    }
}
