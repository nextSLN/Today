import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userProfileManager: UserProfileManager
    @State private var currentStep = 0
    @State private var name = ""
    @State private var age = ""
    @State private var gender = UserProfile.Gender.male
    @State private var height = ""
    @State private var weight = ""
    @State private var activityLevel = UserProfile.ActivityLevel.moderatelyActive
    @State private var fitnessGoal = UserProfile.FitnessGoal.maintenance
    @State private var dietaryRestrictions: Set<DietaryRestriction> = []
    
    var body: some View {
        ZStack {
            Theme.backgroundBlack.ignoresSafeArea()
            
            VStack(spacing: Theme.Layout.standardSpacing) {
                ProgressView(value: Double(currentStep), total: 4)
                    .tint(Theme.premiumRed)
                    .padding()
                
                ScrollView {
                    VStack(spacing: Theme.Layout.largeSpacing) {
                        switch currentStep {
                        case 0:
                            basicInfoView
                        case 1:
                            measurementsView
                        case 2:
                            activityView
                        case 3:
                            dietaryView
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                
                navigationButtons
            }
        }
        .foregroundColor(Theme.textColor)
    }
    
    private var basicInfoView: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Let's get to know you")
                .font(Theme.Typography.title)
            
            TextField("Your Name", text: $name)
                .themedTextField()
            
            TextField("Age", text: $age)
                .themedTextField()
                .keyboardType(.numberPad)
            
            Picker("Gender", selection: $gender) {
                ForEach([UserProfile.Gender.male, .female, .other], id: \.self) { gender in
                    Text(gender.rawValue).tag(gender)
                }
            }
            .pickerStyle(.segmented)
        }
        .cardStyle()
    }
    
    private var measurementsView: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Your Measurements")
                .font(Theme.Typography.title)
            
            TextField("Height (cm)", text: $height)
                .themedTextField()
                .keyboardType(.decimalPad)
            
            TextField("Weight (kg)", text: $weight)
                .themedTextField()
                .keyboardType(.decimalPad)
        }
        .cardStyle()
    }
    
    private var activityView: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Activity Level")
                .font(Theme.Typography.title)
            
            Picker("Activity Level", selection: $activityLevel) {
                ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.wheel)
            
            Text("Fitness Goal")
                .font(Theme.Typography.title)
                .padding(.top)
            
            Picker("Fitness Goal", selection: $fitnessGoal) {
                ForEach(UserProfile.FitnessGoal.allCases, id: \.self) { goal in
                    Text(goal.rawValue).tag(goal)
                }
            }
            .pickerStyle(.segmented)
        }
        .cardStyle()
    }
    
    private var dietaryView: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Dietary Restrictions")
                .font(Theme.Typography.title)
            
            ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                Toggle(restriction.rawValue, isOn: Binding(
                    get: { dietaryRestrictions.contains(restriction) },
                    set: { isOn in
                        if isOn {
                            dietaryRestrictions.insert(restriction)
                        } else {
                            dietaryRestrictions.remove(restriction)
                        }
                    }
                ))
            }
        }
        .cardStyle()
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .secondaryButton()
            }
            
            if currentStep < 3 {
                Button("Next") {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .primaryButton()
            } else {
                Button("Complete") {
                    completeOnboarding()
                }
                .primaryButton(isEnabled: isValidForm)
            }
        }
        .padding()
    }
    
    private var isValidForm: Bool {
        !name.isEmpty &&
        !age.isEmpty &&
        !height.isEmpty &&
        !weight.isEmpty
    }
    
    private func completeOnboarding() {
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
        userProfileManager.completeOnboarding()
    }
}