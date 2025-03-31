import SwiftUI
import HealthKit
import Charts

extension HKWorkout: Identifiable {
    public var id: UUID {
        return uuid
    }
}

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct WorkoutView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingNewWorkout = false
    @State private var isLoading = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Time range selector with improved visual feedback
                    TimeRangeSelector(selectedRange: $selectedTimeRange)
                        .padding(.horizontal)
                    
                    // Quick Stats Section
                    quickStatsSection
                        .transition(.slide)
                    
                    // Activity Overview
                    if selectedTab == 0 {
                        LazyVStack(spacing: Theme.Layout.standardSpacing * 2) {
                            ActivityView(timeRange: selectedTimeRange)
                        }
                    } else {
                        LazyVStack(spacing: Theme.Layout.standardSpacing) {
                            WorkoutsListView(timeRange: selectedTimeRange)
                        }
                    }
                }
                .padding(.vertical)
            }
            .refreshable {
                await refresh()
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewWorkout = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.premiumRed)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewWorkout) {
                NewWorkoutSheet()
            }
            .overlay {
                if isLoading {
                    LoadingView()
                }
            }
            .safeAreaInset(edge: .bottom) {
                segmentedControl
            }
        }
    }
    
    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                QuickStatCard(
                    title: "Week",
                    value: "\(healthKitManager.workoutStats.thisWeekWorkouts)",
                    icon: "figure.run",
                    color: Theme.premiumRed
                )
                
                QuickStatCard(
                    title: "Calories",
                    value: "\(Int(healthKitManager.workoutStats.thisWeekCalories))",
                    icon: "flame.fill",
                    color: Theme.warning
                )
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                QuickStatCard(
                    title: "Minutes",
                    value: formatDuration(healthKitManager.workoutStats.thisWeekDuration),
                    icon: "clock.fill",
                    color: Theme.accentBlue
                )
                
                QuickStatCard(
                    title: "Distance",
                    value: String(format: "%.1f", healthKitManager.workoutStats.totalDistanceThisWeek / 1000),
                    icon: "figure.walk",
                    color: Theme.accentGreen
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var segmentedControl: some View {
        HStack {
            Picker("View", selection: $selectedTab) {
                Text("Activity").tag(0)
                Text("History").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
        }
        .background(.ultraThinMaterial)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    private func refresh() async {
        isLoading = true
        healthKitManager.refreshAllData()
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedRange = range
                    }
                }) {
                    Text(range.rawValue)
                        .font(.system(.subheadline, weight: .medium))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            selectedRange == range ?
                            Theme.premiumRed.opacity(0.1) : Color.clear
                        )
                        .foregroundColor(
                            selectedRange == range ?
                            Theme.premiumRed : .secondary
                        )
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.premiumRed)
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        }
    }
}

struct ActivityView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    let timeRange: TimeRange
    @State private var selectedWorkout: HKWorkout?
    @State private var showingWorkoutDetail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Layout.standardSpacing * 2) {
                // Weekly Overview
                weeklyOverview
                
                // Personal Bests
                personalBests
                
                // Recent Activity
                recentActivity
                
                // Fitness Trends
                fitnessTrends
            }
            .padding()
        }
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
    }
    
    private var weeklyOverview: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Weekly Overview")
                .font(Theme.Typography.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    title: "Total Workouts",
                    value: "\(healthKitManager.workoutStats.thisWeekWorkouts)",
                    icon: "figure.run",
                    color: Theme.premiumRed
                )
                
                StatCard(
                    title: "Active Minutes",
                    value: formatDuration(healthKitManager.workoutStats.thisWeekDuration),
                    icon: "clock",
                    color: Theme.accentBlue
                )
                
                StatCard(
                    title: "Calories Burned",
                    value: "\(Int(healthKitManager.workoutStats.thisWeekCalories))",
                    icon: "flame",
                    color: Theme.warning
                )
                
                StatCard(
                    title: "Distance",
                    value: String(format: "%.1f km", healthKitManager.workoutStats.totalDistanceThisWeek / 1000),
                    icon: "figure.walk",
                    color: Theme.accentGreen
                )
            }
        }
        .cardStyle()
    }
    
    private var personalBests: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Personal Bests")
                .font(Theme.Typography.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Layout.standardSpacing) {
                    ForEach(healthKitManager.workoutStats.personalBests, id: \.date) { best in
                        PersonalBestCard(personalBest: best)
                    }
                }
            }
        }
    }
    
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Recent Activity")
                .font(Theme.Typography.headline)
            
            ForEach(healthKitManager.recentWorkouts.prefix(3), id: \.uuid) { workout in
                WorkoutCard(workout: workout)
                    .onTapGesture {
                        selectedWorkout = workout
                    }
            }
        }
    }
    
    private var fitnessTrends: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Fitness Trends")
                .font(Theme.Typography.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VO2 Max")
                        .font(Theme.Typography.subheadline)
                    Text(String(format: "%.1f", healthKitManager.vo2Max))
                        .font(Theme.Typography.title)
                    Text("ml/kg·min")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resting HR")
                        .font(Theme.Typography.subheadline)
                    Text("\(Int(healthKitManager.restingHeartRate))")
                        .font(Theme.Typography.title)
                    Text("BPM")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.secondaryText)
                }
            }
            .padding()
            .cardStyle()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

struct WorkoutsListView: View {
    let timeRange: TimeRange
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Layout.standardSpacing) {
                // Workout Stats Summary
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Layout.standardSpacing) {
                    StatSummaryCard(
                        title: "This Week",
                        value: "\(healthKitManager.workoutStats.thisWeekWorkouts)",
                        subtitle: "Workouts",
                        icon: "figure.run",
                        color: Theme.premiumRed
                    )
                    
                    StatSummaryCard(
                        title: "Calories Burned",
                        value: "\(Int(healthKitManager.workoutStats.thisWeekCalories))",
                        subtitle: "kcal this week",
                        icon: "flame.fill",
                        color: Theme.accentBlue
                    )
                    
                    StatSummaryCard(
                        title: "Active Time",
                        value: formatDuration(healthKitManager.workoutStats.thisWeekDuration),
                        subtitle: "this week",
                        icon: "clock.fill",
                        color: Theme.accentGreen
                    )
                    
                    StatSummaryCard(
                        title: "Distance",
                        value: String(format: "%.1f", healthKitManager.workoutStats.totalDistanceThisWeek / 1000),
                        subtitle: "km this week",
                        icon: "figure.walk",
                        color: Theme.warning
                    )
                }
                .padding(.horizontal)
                
                // Personal Bests Section
                if !healthKitManager.workoutStats.personalBests.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
                        Text("Personal Bests")
                            .font(Theme.Typography.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Theme.Layout.standardSpacing) {
                                ForEach(healthKitManager.workoutStats.personalBests, id: \.date) { best in
                                    PersonalBestCard(personalBest: best)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Recent Workouts List
                VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
                    Text("Recent Workouts")
                        .font(Theme.Typography.headline)
                        .padding(.horizontal)
                    
                    ForEach(healthKitManager.recentWorkouts, id: \.uuid) { workout in
                        WorkoutCard(workout: workout)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

struct StatSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            
            Text(value)
                .font(Theme.Typography.title)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
    }
}

struct PersonalBestCard: View {
    let personalBest: HealthKitManager.WorkoutPersonalBest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text(workoutTypeToString(personalBest.type))
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", personalBest.value))
                    .font(Theme.Typography.title)
                    .fontWeight(.bold)
                
                Text(personalBest.unit)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            
            Text(formatDate(personalBest.date))
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.secondaryText)
        }
        .frame(width: 160)
        .padding()
        .cardStyle()
    }
    
    private func workoutTypeToString(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        default: return "Workout"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct WorkoutCard: View {
    let workout: HKWorkout
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.smallSpacing) {
            HStack {
                Image(systemName: workoutIcon)
                    .foregroundColor(Theme.premiumRed)
                Text(workoutTypeToString(workout.workoutActivityType))
                    .font(Theme.Typography.headline)
                Spacer()
                ThemeTag(text: "Completed", color: Theme.premiumRed)
            }
            
            HStack {
                WorkoutStat(
                    icon: "clock",
                    value: formatDuration(workout.duration)
                )
                
                if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                    WorkoutStat(
                        icon: "flame.fill",
                        value: "\(Int(calories)) cal"
                    )
                }
                
                if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
                    WorkoutStat(
                        icon: "speedometer",
                        value: String(format: "%.1f km", distance / 1000)
                    )
                }
                
                if let heartRate = healthKitManager.workoutStats.averageHeartRatePerWorkout[workout.uuid] {
                    WorkoutStat(
                        icon: "heart.fill",
                        value: "\(Int(heartRate)) bpm"
                    )
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .cardStyle()
    }
    
    private var workoutIcon: String {
        switch workout.workoutActivityType {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .walking: return "figure.walk"
        case .swimming: return "figure.pool.swim"
        case .hiking: return "mountain.2"
        default: return "figure.mixed.cardio"
        }
    }
    
    private func workoutTypeToString(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        default: return "Workout"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return hours > 0 ? "\(hours)h \(remainingMinutes)m" : "\(minutes)m"
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.subheadline)
                .foregroundColor(isSelected ? Theme.textColor : Theme.secondaryText)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                        .fill(isSelected ? Theme.secondaryBlack : Color.clear)
                )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            
            Text(value)
                .font(Theme.Typography.title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
    }
}

struct ActivityRings: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        HStack(spacing: Theme.Layout.standardSpacing) {
            ThemeCircleProgress(
                progress: Double(healthKitManager.stepsToday) / 10000.0,
                color: Theme.premiumRed,
                lineWidth: 15,
                size: 150,
                showText: true,
                icon: nil
            )
            
            VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
                RingProgressDetail(
                    title: "Move",
                    value: "\(Int(healthKitManager.activeCaloriesDay)) / \(Int(healthKitManager.workoutStats.thisWeekCalories / 7)) kcal",
                    color: Theme.premiumRed
                )
                
                RingProgressDetail(
                    title: "Exercise",
                    value: "\(healthKitManager.exerciseMinutes) / 30 min",
                    color: Theme.accentGreen
                )
                
                RingProgressDetail(
                    title: "Stand",
                    value: "\(Int(healthKitManager.workoutStats.thisWeekDuration / 3600)) / 12 hrs",
                    color: Theme.accentBlue
                )
            }
        }
        .padding()
        .cardStyle()
    }
}

struct RingProgressDetail: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(Theme.Typography.subheadline)
            
            Spacer()
            
            Text(value)
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.secondaryText)
        }
    }
}

struct ActivityStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(Theme.Typography.subheadline)
                Spacer()
            }
            
            Text(value)
                .font(Theme.Typography.headline)
                .padding(.top, 4)
            
            Text(subtitle)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.secondaryText)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width), height: 4)
                }
                .cornerRadius(2)
            }
            .frame(height: 4)
            .padding(.top, 8)
        }
        .padding()
        .cardStyle()
    }
}

struct WorkoutStat: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(Theme.secondaryText)
            Text(value)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textColor)
        }
    }
}

struct NewWorkoutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var selectedWorkoutType = "Running"
    @State private var duration = 30.0
    @State private var intensity = "Medium"
    @State private var distance = 0.0
    @State private var showingTimer = false  // Fixed typo here
    @State private var workoutInProgress = false
    @State private var elapsedTime = 0
    @State private var timer: Timer?
    
    let workoutTypes = ["Running", "Walking", "Cycling", "Swimming", "Strength", "HIIT"]
    let intensities = ["Low", "Medium", "High"]
    
    var body: some View {
        NavigationView {
            if showingTimer {
                workoutTimerView
            } else {
                workoutSetupView
            }
        }
    }
    
    private var workoutSetupView: some View {
        Form {
            Section {
                Picker("Workout Type", selection: $selectedWorkoutType) {
                    ForEach(workoutTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                
                if ["Running", "Walking", "Cycling"].contains(selectedWorkoutType) {
                    VStack(alignment: .leading) {
                        Text("Target Distance (km)")
                        HStack {
                            Slider(value: $distance, in: 0.5...42.2, step: 0.5)
                            Text(String(format: "%.1f", distance))
                                .foregroundColor(Theme.secondaryText)
                        }
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Duration (minutes)")
                    HStack {
                        Slider(value: $duration, in: 5...120, step: 5)
                        Text("\(Int(duration))")
                            .foregroundColor(Theme.secondaryText)
                    }
                }
                
                Picker("Intensity", selection: $intensity) {
                    ForEach(intensities, id: \.self) { intensity in
                        Text(intensity)
                    }
                }
            }
            
            Section {
                Button(action: { showingTimer = true }) {
                    Text("Start Workout")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                }
                .listRowBackground(Theme.premiumRed)
            }
        }
        .navigationTitle("New Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private var workoutTimerView: some View {
        VStack(spacing: Theme.Layout.largeSpacing) {
            // Timer Display
            VStack {
                Text(selectedWorkoutType)
                    .font(Theme.Typography.title)
                    .padding(.bottom)
                
                Text(timeString(from: elapsedTime))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.premiumRed)
                    .monospacedDigit()
                
                if ["Running", "Walking", "Cycling"].contains(selectedWorkoutType) {
                    Text(String(format: "Target: %.1f km", distance))
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.secondaryText)
                }
            }
            .padding()
            .cardStyle()
            
            // Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Layout.standardSpacing) {
                StatBox(title: "Calories", value: "\(Int(Double(elapsedTime) * 0.15))", unit: "kcal")
                StatBox(title: "Heart Rate", value: "\(Int(Double.random(in: 120...150)))", unit: "bpm")
                if ["Running", "Walking", "Cycling"].contains(selectedWorkoutType) {
                    StatBox(title: "Pace", value: "5'30\"", unit: "/km")
                    StatBox(title: "Distance", value: "2.5", unit: "km")
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Control Buttons
            HStack(spacing: Theme.Layout.standardSpacing) {
                Button(action: {
                    showingTimer = false
                    stopWorkout()
                }) {
                    Text("End")
                        .font(Theme.Typography.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.premiumRed)
                        .cornerRadius(Theme.Layout.cornerRadius)
                }
                
                Button(action: toggleWorkout) {
                    Image(systemName: workoutInProgress ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Theme.accentBlue)
                        .clipShape(Circle())
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Workout in Progress")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            stopWorkout()
        }
    }
    
    private func toggleWorkout() {
        workoutInProgress.toggle()
        if workoutInProgress {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                elapsedTime += 1
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func stopWorkout() {
        timer?.invalidate()
        timer = nil
        workoutInProgress = false
        // Here you would normally save the workout data
    }
    
    private func timeString(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.secondaryText)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(Theme.Typography.title)  // Changed from title2 to title
                    .fontWeight(.bold)
                
                Text(unit)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardStyle()
    }
}

struct WorkoutDetailView: View {
    let workout: HKWorkout
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Layout.standardSpacing) {
                // Header
                workoutHeader
                
                // Stats Grid
                statsGrid
                
                // Heart Rate Chart
                if let heartRate = healthKitManager.workoutStats.averageHeartRatePerWorkout[workout.uuid] {
                    heartRateSection(heartRate)
                }
                
                // Route Map (if available)
                if workout.totalDistance != nil {
                    routeMap
                }
                
                // Splits (if available)
                if let distance = workout.totalDistance {
                    splitsSection(distance)
                }
            }
            .padding()
        }
        .navigationTitle(workoutTypeToString(workout.workoutActivityType))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var workoutHeader: some View {
        VStack(spacing: Theme.Layout.standardSpacing) {
            Image(systemName: workoutIcon)
                .font(.system(size: 40))
                .foregroundColor(Theme.premiumRed)
            
            Text(formatDate(workout.startDate))
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.secondaryText)
            
            Text(formatDuration(workout.duration))
                .font(Theme.Typography.title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatBox(
                title: "Distance",
                value: String(format: "%.2f", workout.totalDistance?.doubleValue(for: .meter()) ?? 0 / 1000),
                unit: "km"
            )
            
            StatBox(
                title: "Calories",
                value: "\(Int(workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0))",
                unit: "kcal"
            )
            
            if let heartRate = healthKitManager.workoutStats.averageHeartRatePerWorkout[workout.uuid] {
                StatBox(
                    title: "Avg Heart Rate",
                    value: "\(Int(heartRate))",
                    unit: "BPM"
                )
            }
            
            StatBox(
                title: "Pace",
                value: formatPace(distance: workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
                                duration: workout.duration),
                unit: "/km"
            )
        }
    }
    
    private func heartRateSection(_ averageHeartRate: Double) -> some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Heart Rate")
                .font(Theme.Typography.headline)
            
            // Placeholder for heart rate chart
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .fill(Theme.secondaryBlack)
                .frame(height: 200)
                .overlay(
                    Text("Average: \(Int(averageHeartRate)) BPM")
                        .foregroundColor(Theme.textColor)
                )
        }
        .cardStyle()
    }
    
    private var routeMap: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Route")
                .font(Theme.Typography.headline)
            
            // Placeholder for map
            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                .fill(Theme.secondaryBlack)
                .frame(height: 200)
        }
        .cardStyle()
    }
    
    private func splitsSection(_ distance: HKQuantity) -> some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Splits")
                .font(Theme.Typography.headline)
            
            // Placeholder for splits
            ForEach(0..<Int(distance.doubleValue(for: .meter()) / 1000), id: \.self) { km in
                HStack {
                    Text("Km \(km + 1)")
                    Spacer()
                    Text("--:--")
                }
                .padding(.vertical, 4)
            }
        }
        .cardStyle()
    }
    
    private var workoutIcon: String {
        switch workout.workoutActivityType {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .walking: return "figure.walk"
        case .swimming: return "figure.pool.swim"
        case .hiking: return "mountain.2"
        default: return "figure.mixed.cardio"
        }
    }
    
    private func workoutTypeToString(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        default: return "Workout"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return hours > 0 ? "\(hours)h \(remainingMinutes)m" : "\(minutes)m"
    }
    
    private func formatPace(distance: Double, duration: TimeInterval) -> String {
        guard distance > 0 else { return "--:--" }
        let paceSeconds = duration / (distance / 1000)
        let minutes = Int(paceSeconds / 60)
        let seconds = Int(paceSeconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}
