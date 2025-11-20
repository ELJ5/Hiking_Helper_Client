//
//  StateSelectionView.swift
//  Hiking Helper
//
//  Created by Eliana Johnson on 11/20/25.
//

import SwiftUI

// MARK: - State Selection View (Reusable for Onboarding & Settings)

struct StateSelectionView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var dataManager: DataManager
    
    var isOnboarding: Bool = false
    var onComplete: (() -> Void)? = nil
    
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    
    // Filter states based on search
    var filteredStates: [StateData] {
        if searchText.isEmpty {
            return StateData.allStates
        }
        return StateData.allStates.filter { state in
            state.name.localizedCaseInsensitiveContains(searchText) ||
            state.code.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // States with trail data
    var availableStates: [StateData] {
        filteredStates.filter { $0.hasTrailData }
    }
    
    // States without trail data
    var unavailableStates: [StateData] {
        filteredStates.filter { !$0.hasTrailData }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header for onboarding
            if isOnboarding {
                VStack(spacing: 12) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Select Your States")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Choose the states where you'd like to explore trails. You can select multiple states.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }
            
            // Selected states summary
            if !userPreferences.trailPreferences.selectedStates.isEmpty {
                SelectedStatesSummary(
                    selectedStates: userPreferences.trailPreferences.selectedStates,
                    onClear: {
                        userPreferences.clearSelectedStates()
                    }
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search states", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // State list
            List {
                // Available states section
                if !availableStates.isEmpty {
                    Section(header: Text("Available States (\(availableStates.count))")) {
                        ForEach(availableStates, id: \.code) { state in
                            StateRow(
                                state: state,
                                isSelected: userPreferences.isStateSelected(state.code),
                                onToggle: {
                                    userPreferences.toggleState(state.code)
                                }
                            )
                        }
                    }
                }
                
                // Unavailable states section
                if !unavailableStates.isEmpty {
                    Section(header: Text("Coming Soon (\(unavailableStates.count))")) {
                        ForEach(unavailableStates, id: \.code) { state in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(state.name)
                                        .foregroundColor(.secondary)
                                    Text(state.code)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("No data")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(4)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            
            // Bottom button for onboarding
            if isOnboarding {
                VStack(spacing: 12) {
                    if userPreferences.trailPreferences.selectedStates.isEmpty {
                        Text("Please select at least one state")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Button(action: {
                        // Reload trails for selected states
                        dataManager.reloadForStateChange()
                        onComplete?()
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                userPreferences.trailPreferences.selectedStates.isEmpty
                                    ? Color.gray
                                    : Color.green
                            )
                            .cornerRadius(12)
                    }
                    .disabled(userPreferences.trailPreferences.selectedStates.isEmpty)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle(isOnboarding ? "" : "Select States")
        .navigationBarTitleDisplayMode(isOnboarding ? .inline : .large)
        .toolbar {
            if !isOnboarding {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Reload trails for selected states
                        dataManager.reloadForStateChange()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - State Row

struct StateRow: View {
    let state: StateData
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.name)
                        .foregroundColor(.primary)
                    Text(state.code)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Selected States Summary

struct SelectedStatesSummary: View {
    let selectedStates: [String]
    let onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Selected: \(selectedStates.count) state\(selectedStates.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: onClear) {
                    Text("Clear All")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Chips for selected states
            FlowLayout(spacing: 8) {
                ForEach(selectedStates, id: \.self) { stateCode in
                    StateChip(stateCode: stateCode)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - State Chip

struct StateChip: View {
    let stateCode: String
    
    var body: some View {
        Text(stateCode)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.2))
            .foregroundColor(.green)
            .cornerRadius(16)
    }
}

// MARK: - Flow Layout (for chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Settings State Selection (Wrapper)

struct SettingsStateSelectionView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        StateSelectionView(isOnboarding: false)
            .environmentObject(userPreferences)
            .environmentObject(dataManager)
    }
}

// MARK: - Onboarding State Selection (Wrapper)

struct OnboardingStateSelectionView: View {
    @EnvironmentObject var userPreferences: UserPreferences
    @EnvironmentObject var dataManager: DataManager
    var onComplete: () -> Void
    
    var body: some View {
        StateSelectionView(isOnboarding: true, onComplete: onComplete)
            .environmentObject(userPreferences)
            .environmentObject(dataManager)
    }
}

// MARK: - Previews

struct StateSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let prefs = UserPreferences()
        let dataManager = DataManager(userPreferences: prefs)
        
        Group {
            // Onboarding version
            NavigationStack {
                StateSelectionView(isOnboarding: true)
                    .environmentObject(prefs)
                    .environmentObject(dataManager)
            }
            .previewDisplayName("Onboarding")
            
            // Settings version
            NavigationStack {
                StateSelectionView(isOnboarding: false)
                    .environmentObject(prefs)
                    .environmentObject(dataManager)
            }
            .previewDisplayName("Settings")
        }
    }
}
