import SwiftUI
import HealthKit

@main
struct FitnessApp: App {
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var userProfileManager = UserProfileManager()
    @StateObject private var mealService: MealService
    
    init() {
        let profileManager = UserProfileManager()
        _userProfileManager = StateObject(wrappedValue: profileManager)
        _mealService = StateObject(wrappedValue: MealService(userProfileManager: profileManager))
    }
    
    var body: some Scene {
        WindowGroup {
            if userProfileManager.isOnboardingComplete {
                MainTabView()
                    .environmentObject(healthKitManager)
                    .environmentObject(userProfileManager)
                    .environmentObject(mealService)
            } else {
                OnboardingView()
                    .environmentObject(userProfileManager)
            }
        }
    }
}

class UserProfileManager: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var isOnboardingComplete: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let userProfileKey = "userProfile"
    private let onboardingKey = "onboardingComplete"
    
    init() {
        loadProfile()
    }
    
    func loadProfile() {
        isOnboardingComplete = userDefaults.bool(forKey: onboardingKey)
        if let data = userDefaults.data(forKey: userProfileKey) {
            userProfile = try? JSONDecoder().decode(UserProfile.self, from: data)
        }
    }
    
    func saveProfile(_ profile: UserProfile) {
        userProfile = profile
        if let encoded = try? JSONEncoder().encode(profile) {
            userDefaults.set(encoded, forKey: userProfileKey)
        }
    }
    
    func completeOnboarding() {
        isOnboardingComplete = true
        userDefaults.set(true, forKey: onboardingKey)
    }
}