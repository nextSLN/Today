import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userProfileManager: UserProfileManager
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Layout.standardSpacing) {  // Reduced spacing
                    // Profile Header
                    VStack(spacing: Theme.Layout.standardSpacing) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Theme.premiumRed)
                            .padding(.top, Theme.Layout.standardSpacing)  // Added top padding
                        
                        Text(userProfileManager.userProfile?.name ?? "User")
                            .font(Theme.Typography.title)
                        
                        Button("Edit Profile") {
                            showingEditProfile = true
                        }
                        .primaryButton()
                        .frame(maxWidth: 200)
                        .padding(.bottom, Theme.Layout.smallSpacing)  // Added bottom padding
                    }
                    .cardStyle()
                    
                    // Stats Section
                    statsSection
                    
                    // Goals Section
                    goalsSection
                    
                    // Settings Section
                    settingsSection
                }
                .padding(.top, Theme.Layout.smallSpacing)  // Added top padding
                .padding(.horizontal)
            }
            .background(Theme.backgroundBlack)
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileSheet()
            }
        }
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Your Stats")
                .font(Theme.Typography.headline)
            
            HStack {
                StatItem(
                    title: "Height",
                    value: String(format: "%.1f", userProfileManager.userProfile?.height ?? 0),
                    unit: "cm"
                )
                
                StatItem(
                    title: "Weight",
                    value: String(format: "%.1f", userProfileManager.userProfile?.weight ?? 0),
                    unit: "kg"
                )
                
                StatItem(
                    title: "BMI",
                    value: String(format: "%.1f", userProfileManager.userProfile?.bmi ?? 0),
                    unit: nil
                )
            }
        }
        .cardStyle()
    }
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Your Goals")
                .font(Theme.Typography.headline)
            
            VStack(alignment: .leading, spacing: Theme.Layout.smallSpacing) {
                GoalRow(
                    icon: "figure.walk",
                    title: "Daily Steps",
                    value: "10,000 steps"
                )
                
                GoalRow(
                    icon: "flame.fill",
                    title: "Daily Calories",
                    value: "\(userProfileManager.userProfile?.dailyCalorieNeeds ?? 2000) kcal"
                )
                
                GoalRow(
                    icon: "figure.walk.motion",
                    title: "Weekly Workouts",
                    value: "4 sessions"
                )
            }
        }
        .cardStyle()
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Settings")
                .font(Theme.Typography.headline)
            
            VStack(spacing: Theme.Layout.smallSpacing) {
                SettingsRow(icon: "bell.fill", title: "Notifications") {
                    showingSettings = true
                }
                
                SettingsRow(icon: "person.2.fill", title: "Share Progress") {
                    showingSettings = true
                }
                
                SettingsRow(icon: "gear", title: "Preferences") {
                    showingSettings = true
                }
                
                SettingsRow(icon: "questionmark.circle", title: "Help & Support") {
                    showingSettings = true
                }
            }
        }
        .cardStyle()
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let unit: String?
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.secondaryText)
            
            Text(value)
                .font(Theme.Typography.headline)
            
            if let unit = unit {
                Text(unit)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct GoalRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.premiumRed)
                .frame(width: 30)
            
            Text(title)
                .font(Theme.Typography.subheadline)
            
            Spacer()
            
            Text(value)
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.secondaryText)
        }
        .padding(.vertical, 8)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.premiumRed)
                    .frame(width: 30)
                
                Text(title)
                    .font(Theme.Typography.subheadline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.secondaryText)
            }
            .padding(.vertical, 8)
        }
    }
}

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfileManager: UserProfileManager
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var gender: UserProfile.Gender = .male
    @State private var activityLevel: UserProfile.ActivityLevel = .moderatelyActive
    @State private var fitnessGoal: UserProfile.FitnessGoal = .maintenance

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                    TextField("Height (cm)", text: $height)
                        .keyboardType(.decimalPad)
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                    
                    Picker("Gender", selection: $gender) {
                        ForEach([UserProfile.Gender.male, .female, .other], id: \.self) { gender in
                            Text(gender.rawValue.capitalized).tag(gender)
                        }
                    }
                }
                
                Section(header: Text("Fitness Profile")) {
                    Picker("Activity Level", selection: $activityLevel) {
                        ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    
                    Picker("Fitness Goal", selection: $fitnessGoal) {
                        ForEach(UserProfile.FitnessGoal.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
        }
    }
    
    private func loadCurrentProfile() {
        guard let profile = userProfileManager.userProfile else { return }
        name = profile.name
        age = String(profile.age)
        height = String(profile.height)
        weight = String(profile.weight)
        gender = profile.gender
        activityLevel = profile.activityLevel
        if let firstGoal = profile.fitnessGoals.first {
            fitnessGoal = firstGoal
        }
    }
    
    private func saveProfile() {
        guard let ageInt = Int(age),
              let heightDouble = Double(height),
              let weightDouble = Double(weight) else { return }
        
        let profile = UserProfile(
            name: name,
            age: ageInt,
            gender: gender,
            height: heightDouble,
            weight: weightDouble
        )
        
        userProfileManager.saveProfile(profile)
        dismiss()
    }
}