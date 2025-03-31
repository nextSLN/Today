import SwiftUI
import HealthKit

struct DashboardView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var userProfileManager: UserProfileManager
    @State private var selectedDate = Date()
    @State private var showingStreak = true
    @State private var showingWaterIntakeSheet = false
    @State private var visibleSections: Set<String> = []
    private let waterGoal: Double = 2.5 // Liters
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Layout.standardSpacing) {
                if showingStreak {
                    streakView
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, Theme.Layout.smallSpacing)
                }
                
                VStack(spacing: Theme.Layout.standardSpacing) {
                    dateHeader
                        .onAppear { visibleSections.insert("header") }
                        .onDisappear { visibleSections.remove("header") }
                    
                    progressGrid
                        .onAppear { visibleSections.insert("progress") }
                        .onDisappear { visibleSections.remove("progress") }
                }
                
                VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
                    Text("Health Metrics")
                        .font(Theme.Typography.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: Theme.Layout.standardSpacing) {
                            healthMetricCards
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, Theme.Layout.standardSpacing)
                .onAppear { visibleSections.insert("metrics") }
                .onDisappear { visibleSections.remove("metrics") }
            }
            .padding(.vertical, Theme.Layout.standardSpacing)
        }
        .background(Theme.backgroundBlack)
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Today")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.textColor)
            }
        }
        .refreshable {
            await refresh()
        }
    }
    
    private var streakView: some View {
        StreakBanner(streak: healthKitManager.currentStreak) {
            withAnimation(.easeInOut) {
                showingStreak = false
            }
        }
        .padding(.top)
    }
    
    private var dateHeader: some View {
        HStack {
            Text("Today's Progress")
                .font(Theme.Typography.title)
            Spacer()
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()
        }
        .padding(.horizontal)
    }
    
    private var progressGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            Group {
                if visibleSections.contains("progress") {
                    stepsCard
                    caloriesCard
                    waterCard
                    exerciseCard
                }
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut, value: visibleSections)
    }
    
    private var healthMetricCards: some View {
        Group {
            if visibleSections.contains("metrics") {
                heartRateCard
                bloodPressureCard
                sleepCard
                vo2MaxCard
            }
        }
    }
    
    private var heartRateCard: some View {
        HealthMetricCard(
            title: "Heart Rate",
            value: "\(Int(healthKitManager.heartRate))",
            unit: "BPM",
            icon: "heart.fill",
            color: Theme.premiumRed,
            subtitle: "Resting: \(Int(healthKitManager.restingHeartRate)) BPM"
        )
    }
    
    private var bloodPressureCard: some View {
        HealthMetricCard(
            title: "Blood Pressure",
            value: "\(Int(healthKitManager.bloodPressure.systolic))/\(Int(healthKitManager.bloodPressure.diastolic))",
            unit: "mmHg",
            icon: "waveform.path.ecg",
            color: Theme.warning,
            subtitle: "Last checked: \(formatDate(healthKitManager.bloodPressure.timestamp))"
        )
    }
    
    private var sleepCard: some View {
        HealthMetricCard(
            title: "Sleep",
            value: "\(Int(healthKitManager.sleepAnalysis.totalSleepHours))",
            unit: "hours",
            icon: "moon.fill",
            color: Theme.accentBlue,
            subtitle: "Deep sleep: \(Int(healthKitManager.sleepAnalysis.deepSleepHours))h"
        )
    }
    
    private var vo2MaxCard: some View {
        HealthMetricCard(
            title: "VO2 Max",
            value: String(format: "%.1f", healthKitManager.vo2Max),
            unit: "ml/kg·min",
            icon: "lungs.fill",
            color: Theme.accentGreen,
            subtitle: getFitnessLevel(vo2Max: healthKitManager.vo2Max)
        )
    }
    
    private var stepsCard: some View {
        DashboardCard(
            title: "Steps",
            value: "\(healthKitManager.stepsToday)",
            target: "10,000",
            icon: "figure.walk",
            progress: Double(healthKitManager.stepsToday) / 10000.0,
            color: Theme.accentBlue,
            subtitle: "\(Int((Double(healthKitManager.stepsToday) / 10000.0) * 100))% of goal"
        )
        .dashboardCardStyle()
    }
    
    private var caloriesCard: some View {
        DashboardCard(
            title: "Active Calories",
            value: "\(Int(healthKitManager.activeCaloriesDay))",
            target: "\(userProfileManager.userProfile?.dailyCalorieNeeds ?? 2000)",
            icon: "flame.fill",
            progress: healthKitManager.activeCaloriesDay / Double(userProfileManager.userProfile?.dailyCalorieNeeds ?? 2000),
            color: Theme.premiumRed,
            subtitle: "BMR: \(Int(userProfileManager.userProfile?.bmr ?? 0)) cal"
        )
        .dashboardCardStyle()
    }
    
    private var waterCard: some View {
        Button(action: { showingWaterIntakeSheet = true }) {
            DashboardCard(
                title: "Water",
                value: String(format: "%.1fL", healthKitManager.nutritionData.waterIntake),
                target: "\(String(format: "%.1f", waterGoal))L",
                icon: "drop.fill",
                progress: healthKitManager.nutritionData.waterIntake / waterGoal,
                color: Color(red: 0.0, green: 0.6, blue: 0.9),
                subtitle: "\(Int((healthKitManager.nutritionData.waterIntake / waterGoal) * 100))% of goal"
            )
        }
        .sheet(isPresented: $showingWaterIntakeSheet) {
            WaterIntakeSheet()
        }
        .dashboardCardStyle()
    }
    
    private var exerciseCard: some View {
        DashboardCard(
            title: "Exercise",
            value: "\(healthKitManager.exerciseMinutes)",
            target: "60",
            icon: "heart.fill",
            progress: Double(healthKitManager.exerciseMinutes) / 60.0,
            color: Theme.accentGreen,
            subtitle: "Zone: \(getHeartRateZone(bpm: Int(healthKitManager.heartRate)))"
        )
        .dashboardCardStyle()
    }
    
    private func getHeartRateZone(bpm: Int) -> String {
        switch bpm {
        case 0..<60: return "Rest"
        case 60..<100: return "Light"
        case 100..<140: return "Moderate"
        case 140..<170: return "Vigorous"
        default: return "Peak"
        }
    }
    
    private func getFitnessLevel(vo2Max: Double) -> String {
        switch vo2Max {
        case 0..<30: return "Fair"
        case 30..<40: return "Good"
        case 40..<50: return "Very Good"
        default: return "Excellent"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func refresh() async {
        healthKitManager.refreshAllData()
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

// Optimized card views using ViewModifier for consistent styling
struct DashboardCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.secondaryBlack)
            .cornerRadius(Theme.Layout.cornerRadius)
    }
}

extension View {
    func dashboardCardStyle() -> some View {
        modifier(DashboardCardModifier())
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    let target: String
    let icon: String
    let progress: Double
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                Text(title)
                    .font(Theme.Typography.subheadline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Progress circle and stats
            VStack(spacing: Theme.Layout.standardSpacing) {
                ThemeCircleProgress(
                    progress: progress,
                    color: color,
                    size: 60,
                    showText: true
                )
                
                // Stats
                VStack(alignment: .center, spacing: 4) {
                    Text(value)
                        .font(Theme.Typography.headline)
                        .fontWeight(.semibold)
                    Text("Goal: \(target)")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.secondaryText)
                    Text(subtitle)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom)
        }
        .background(Theme.secondaryBlack)
        .cornerRadius(Theme.Layout.cornerRadius)
    }
}

struct MealPreviewCard: View {
    let mealType: MealType
    @EnvironmentObject var mealService: MealService
    
    var meal: Meal? {
        mealService.getMeal(for: mealType, on: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.smallSpacing) {
            Text(mealType.rawValue)
                .font(Theme.Typography.subheadline)
            
            if let meal = meal, let imageURL = meal.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 80)
                        .cornerRadius(Theme.Layout.cornerRadius)
                } placeholder: {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 30))
                        .foregroundColor(Theme.premiumRed)
                        .frame(width: 120, height: 80)
                }
            } else {
                Image(systemName: "fork.knife")
                    .font(.system(size: 30))
                    .foregroundColor(Theme.premiumRed)
                    .frame(width: 120, height: 80)
            }
            
            Text(meal?.name ?? "Tap to generate")
                .font(Theme.Typography.caption)
                .lineLimit(1)
                .foregroundColor(meal != nil ? Theme.textColor : Theme.secondaryText)
        }
        .frame(width: 120)
        .cardStyle()
    }
}

struct MealDetailView: View {
    let mealType: MealType
    @EnvironmentObject var mealService: MealService
    @State private var selectedDate = Date()
    
    var meal: Meal? {
        mealService.getMeal(for: mealType, on: selectedDate)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Layout.standardSpacing) {
                if let meal = meal {
                    mealDetail(meal: meal)
                } else {
                    emptyMealView
                }
            }
            .padding()
        }
        .background(Theme.backgroundBlack)
        .navigationTitle(mealType.rawValue)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    mealService.generateMeal(for: mealType, on: selectedDate)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Theme.premiumRed)
                }
            }
        }
    }
    
    private func mealDetail(meal: Meal) -> some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            if let imageURL = meal.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .cornerRadius(Theme.Layout.cornerRadius)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Theme.secondaryBlack)
                        .frame(height: 200)
                }
            }
            
            Text(meal.name)
                .font(Theme.Typography.title)
                .fontWeight(.bold)
            
            // Nutrition info
            VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
                Text("Nutrition")
                    .font(Theme.Typography.headline)
                
                HStack {
                    NutritionInfo(label: "Calories", value: "\(meal.calories)", unit: "kcal")
                    NutritionInfo(label: "Protein", value: String(format: "%.1f", meal.protein), unit: "g")
                    NutritionInfo(label: "Carbs", value: String(format: "%.1f", meal.carbs), unit: "g")
                    NutritionInfo(label: "Fats", value: String(format: "%.1f", meal.fats), unit: "g")
                }
            }
            .padding()
            .cardStyle()
            
            // Ingredients
            VStack(alignment: .leading, spacing: Theme.Layout.smallSpacing) {
                Text("Ingredients")
                    .font(Theme.Typography.headline)
                
                ForEach(meal.ingredients, id: \.self) { ingredient in
                    HStack(alignment: .top) {
                        Circle()
                            .fill(Theme.premiumRed)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        Text(ingredient)
                            .font(Theme.Typography.body)
                    }
                }
            }
            .padding()
            .cardStyle()
            
            // Instructions
            VStack(alignment: .leading, spacing: Theme.Layout.smallSpacing) {
                Text("Instructions")
                    .font(Theme.Typography.headline)
                
                ForEach(Array(meal.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top) {
                        Text("\(index + 1).")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.premiumRed)
                            .frame(width: 25, alignment: .leading)
                        
                        Text(instruction)
                            .font(Theme.Typography.body)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .cardStyle()
        }
    }
    
    private var emptyMealView: some View {
        VStack(spacing: Theme.Layout.largeSpacing) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(Theme.premiumRed)
                .padding()
            
            Text("No \(mealType.rawValue) Planned Yet")
                .font(Theme.Typography.headline)
            
            Text("Tap the refresh button to generate a personalized meal recommendation based on your profile.")
                .font(Theme.Typography.body)
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.secondaryText)
                .padding()
            
            Button("Generate \(mealType.rawValue)") {
                mealService.generateMeal(for: mealType, on: selectedDate)
            }
            .primaryButton()
            .frame(maxWidth: 250)
            .padding()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }
}

struct StreakBanner: View {
    let streak: Int
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundColor(Theme.premiumRed)
            
            Text("\(streak) Day Streak!")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.textColor)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .padding()
        .background(Theme.secondaryBlack)
        .cornerRadius(Theme.Layout.cornerRadius)
        .padding(.horizontal)
    }
}

struct AchievementCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.Layout.smallSpacing) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(Theme.Typography.title)  // Changed from title2 to title
                .bold()
            
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }
}

struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(Theme.Typography.title)
                    .fontWeight(.bold)
                
                Text(unit)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.secondaryText)
                
                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.secondaryText)
                    .lineLimit(1)
            }
        }
        .frame(width: 140)
        .padding()
        .background(Theme.secondaryBlack)
        .cornerRadius(Theme.Layout.cornerRadius)
    }
}

struct WaterIntakeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var selectedAmount: Double = 0.25
    
    private let amounts: [Double] = [0.25, 0.5, 0.75, 1.0] // In liters
    
    var body: some View {
        NavigationView {
            VStack(spacing: Theme.Layout.largeSpacing) {
                Text("Add Water Intake")
                    .font(Theme.Typography.title)
                    .padding(.top)
                
                Text("\(String(format: "%.2f", selectedAmount))L")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.6, blue: 0.9))
                
                // Quick amount buttons
                HStack(spacing: Theme.Layout.standardSpacing) {
                    ForEach(amounts, id: \.self) { amount in
                        Button(action: { selectedAmount = amount }) {
                            Text("\(Int(amount * 1000))ml")
                                .font(Theme.Typography.body)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    selectedAmount == amount ?
                                    Color(red: 0.0, green: 0.6, blue: 0.9) :
                                    Theme.secondaryBlack
                                )
                                .foregroundColor(selectedAmount == amount ? .white : Theme.textColor)
                                .cornerRadius(20)
                        }
                    }
                }
                
                // Custom slider
                VStack {
                    Slider(value: $selectedAmount, in: 0...2, step: 0.05)
                        .tint(Color(red: 0.0, green: 0.6, blue: 0.9))
                        .padding(.horizontal)
                    
                    HStack {
                        Text("0L")
                        Spacer()
                        Text("2L")
                    }
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.secondaryText)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                
                Button("Add Water") {
                    healthKitManager.addWaterIntake(amount: selectedAmount)
                    dismiss()
                }
                .primaryButton()
                .frame(maxWidth: 200)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
