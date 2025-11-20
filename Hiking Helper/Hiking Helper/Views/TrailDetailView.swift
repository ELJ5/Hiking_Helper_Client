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
    let trail: Trail
    
    @State private var cameraPosition: MapCameraPosition
    @Environment(\.dismiss) var dismiss
    
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
                        .tint(.green)
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
                        .background(Color.green)
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
                    
                    // Quick Stats
                    HStack(spacing: 20) {
                        StatBox(icon: "figure.walk", value: String(format: "%.1f", trail.distanceMiles), label: "Miles", color: .blue)
                        StatBox(icon: "arrow.up.right", value: "\(Int(trail.elevationGainFeet))", label: "Elevation (ft)", color: .orange)
                        StatBox(icon: "gauge.medium", value: trail.difficultyLevel, label: "Difficulty", color: difficultyColor)
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
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
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
                            .background(isCompleted ? Color.orange : Color.green)
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
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
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
            return .gray
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
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Flow Layout (for terrain tags)

//struct FlowLayout: Layout {
//    var spacing: CGFloat = 8
//    
//    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
//        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
//        return result.size
//    }
//    
//    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
//        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
//        for (index, subview) in subviews.enumerated() {
//            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
//                                      y: bounds.minY + result.positions[index].y),
//                         proposal: .unspecified)
//        }
//    }
//    
//    struct FlowResult {
//        var size: CGSize = .zero
//        var positions: [CGPoint] = []
//        
//        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
//            var x: CGFloat = 0
//            var y: CGFloat = 0
//            var rowHeight: CGFloat = 0
//            
//            for subview in subviews {
//                let size = subview.sizeThatFits(.unspecified)
//                
//                if x + size.width > maxWidth && x > 0 {
//                    x = 0
//                    y += rowHeight + spacing
//                    rowHeight = 0
//                }
//                
//                positions.append(CGPoint(x: x, y: y))
//                rowHeight = max(rowHeight, size.height)
//                x += size.width + spacing
//            }
//            
//            self.size = CGSize(width: maxWidth, height: y + rowHeight)
//        }
//    }
//}

// MARK: - Preview

struct TrailDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTrail = Trail(
            id: 1,
            trailName: "Table Rock Trail",
            state: "South Carolina",
            latitude: 35.0211,
            longitude: -82.7314,
            distanceMiles: 6.8,
            elevationGainFeet: 2150,
            difficultyLevel: "Moderate",
            terrainTypes: ["Rocky", "Forest", "Mountain"],
            description: "A beautiful trail leading to stunning views from Table Rock summit. The trail features rocky terrain and forest sections with a rewarding panoramic view at the top.",
            userRating: 4.7,
            completed: false
        )
        
        NavigationStack {
            TrailDetailView(trail: sampleTrail)
                .environmentObject(UserPreferences())
        }
    }
}
