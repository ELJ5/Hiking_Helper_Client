import SwiftUI

// MARK: - Main Goals View

struct GoalsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userPreferences: UserPreferences
    @ObservedObject var dataManager: GoalDataManager
    @State private var selectedFilter: GoalFilter = .all
    @State private var selectedTimeframe: GoalTimeframe = .weekly
    @State private var showingStatistics = false
    @State private var showingGenerateSheet = false
    
    // Standard initializer with shared GoalDataManager
    init(userPreferences: UserPreferences, goalDataManager: GoalDataManager) {
        self.userPreferences = userPreferences
        self.dataManager = goalDataManager
    }
    
    // Preview/test initializer with test data
    init(userPreferences: UserPreferences, withTestData: Bool) {
        self.userPreferences = userPreferences
        self.dataManager = GoalDataManager(withTestData: withTestData)
    }
    
    enum GoalFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
    }
    
    var filteredGoals: [Goal] {
        switch selectedFilter {
        case .all:
            return dataManager.goalsSortedByCompletion()
        case .pending:
            return dataManager.pendingGoals
        case .completed:
            return dataManager.completedGoals
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Header
            ProgressHeaderView(
                completedCount: dataManager.completedGoals.count,
                totalCount: dataManager.goals.count,
                percentage: dataManager.completionPercentage,
                trailsCompleted: userPreferences.trailPreferences.completedTrailCount
            )
            .padding()
            .background(Color(.systemGroupedBackground))
            
            // Statistics Button
            Button(action: { showingStatistics = true }) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("View Statistics")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.accentColor)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(Color(.systemGroupedBackground))
            
            // Filter Picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(GoalFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Goals List
            if dataManager.isLoading {
                LoadingView()
            } else if let error = dataManager.errorMessage {
                ErrorView(message: error) {
                    generateGoals()
                }
            } else if filteredGoals.isEmpty {
                EmptyGoalsView(filter: selectedFilter) {
                    showingGenerateSheet = true
                }
            } else {
                List {
                    ForEach(filteredGoals) { goal in
                        GoalRowView(goal: goal) {
                            dataManager.toggleGoalCompletion(id: goal.id)
                        }
                    }
                    .onDelete { offsets in
                        let goalsToDelete = offsets.map { filteredGoals[$0] }
                        goalsToDelete.forEach { dataManager.deleteGoal(id: $0.id) }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle("Hiking Goals")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "house.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingGenerateSheet = true }) {
                    Image(systemName: "sparkles")
                }
            }
        }
        .sheet(isPresented: $showingGenerateSheet) {
            GenerateGoalsSheet(
                userPreferences: userPreferences,
                selectedTimeframe: $selectedTimeframe
            ) {
                generateGoals()
            }
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView(
                statistics: dataManager.getStatistics(),
                trailsCompleted: userPreferences.trailPreferences.completedTrailCount
            )
        }
    }
    
    private func generateGoals() {
        Task {
            await dataManager.generateGoals(
                from: userPreferences.trailPreferences,
                timeframe: selectedTimeframe
            )
        }
    }
}

// MARK: - Progress Header View

struct ProgressHeaderView: View {
    let completedCount: Int
    let totalCount: Int
    let percentage: Double
    let trailsCompleted: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Goal Progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(completedCount) of \(totalCount) completed")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(percentage))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                    Text("\(trailsCompleted) trails hiked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 12)
                        .animation(.spring(), value: percentage)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Goal Row View

struct GoalRowView: View {
    let goal: Goal
    let onToggle: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(goal.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(goal.title)
                    .font(.headline)
                    .strikethrough(goal.isCompleted)
                    .foregroundColor(goal.isCompleted ? .secondary : .primary)
                
                Text(goal.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label(goal.category.rawValue, systemImage: goal.category.iconName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryColor(for: goal.category).opacity(0.1))
                        .foregroundColor(categoryColor(for: goal.category))
                        .cornerRadius(6)
                    
                    Text(goal.timeframe.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.secondary)
                        .cornerRadius(6)
                }
                
                if goal.isCompleted, let completedAt = goal.completedAt {
                    Text("Completed \(completedAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func categoryColor(for category: GoalCategory) -> Color {
        switch category {
        case .endurance: return .red
        case .elevation: return .purple
        case .distance: return .blue
        case .frequency: return .green
        case .exploration: return .orange
        case .skills: return .teal
        }
    }
}

// MARK: - Generate Goals Sheet

struct GenerateGoalsSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userPreferences: UserPreferences
    @Binding var selectedTimeframe: GoalTimeframe
    let onGenerate: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Your Hiking Profile")) {
                    ProfileRow(title: "Current Capability", value: userPreferences.trailPreferences.currentCapability)
                    ProfileRow(title: "Goal Distance", value: userPreferences.trailPreferences.desiredDistance)
                    ProfileRow(title: "Difficulty", value: userPreferences.trailPreferences.difficulty)
                    ProfileRow(title: "Elevation", value: userPreferences.trailPreferences.elevation)
                    ProfileRow(title: "Frequency", value: userPreferences.trailPreferences.hikingFrequency)
                }
                
                Section(header: Text("Goal Timeframe")) {
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(GoalTimeframe.allCases, id: \.self) { tf in
                            Text(tf.rawValue).tag(tf)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button(action: {
                        onGenerate()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate Personalized Goals")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.accentColor)
                }
            }
            .navigationTitle("Generate Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct ProfileRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value.isEmpty ? "Not set" : value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Empty Goals View

struct EmptyGoalsView: View {
    let filter: GoalsView.GoalFilter
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(emptyStateTitle)
                .font(.headline)
            
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if filter == .all {
                Button(action: onGenerate) {
                    Label("Generate Goals", systemImage: "sparkles")
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateIcon: String {
        switch filter {
        case .all: return "mountain.2"
        case .pending: return "checkmark.circle"
        case .completed: return "trophy"
        }
    }
    
    private var emptyStateTitle: String {
        switch filter {
        case .all: return "No Goals Yet"
        case .pending: return "All Caught Up!"
        case .completed: return "No Completed Goals"
        }
    }
    
    private var emptyStateMessage: String {
        switch filter {
        case .all: return "Generate personalized hiking goals based on your preferences"
        case .pending: return "You've completed all your goals! Time to generate new ones."
        case .completed: return "Complete some goals to see them here"
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating your personalized goals...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onRetry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Statistics View

struct StatisticsView: View {
    @Environment(\.dismiss) var dismiss
    let statistics: GoalStatistics
    let trailsCompleted: Int
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Overview")) {
                    StatRow(title: "Total Goals", value: "\(statistics.totalGoals)", icon: "target")
                    StatRow(title: "Completed", value: "\(statistics.completedGoals)", icon: "checkmark.circle.fill")
                    StatRow(title: "Pending", value: "\(statistics.pendingGoals)", icon: "circle")
                    StatRow(title: "Completion Rate", value: "\(Int(statistics.completionRate))%", icon: "percent")
                    StatRow(title: "Trails Hiked", value: "\(trailsCompleted)", icon: "figure.hiking")
                }
                
                Section(header: Text("By Category")) {
                    ForEach(GoalCategory.allCases, id: \.self) { category in
                        HStack {
                            Label(category.rawValue, systemImage: category.iconName)
                            Spacer()
                            Text("\(statistics.goalsByCategory[category] ?? 0)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if !statistics.recentlyCompleted.isEmpty {
                    Section(header: Text("Recently Completed")) {
                        ForEach(statistics.recentlyCompleted) { goal in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(goal.title)
                                    .font(.subheadline)
                                if let completedAt = goal.completedAt {
                                    Text(completedAt, style: .relative)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
        }
    }
}

// MARK: - Preview

struct GoalsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GoalsView(userPreferences: UserPreferences(), withTestData: true)
        }
    }
}
