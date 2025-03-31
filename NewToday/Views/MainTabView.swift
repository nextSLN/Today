import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @EnvironmentObject var userProfileManager: UserProfileManager
    @State private var selectedTab = 0
    @State private var previousTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                DashboardView()
            }
            .tag(0)
            .tabItem {
                Label("Dashboard", systemImage: "house.fill")
            }
            
            NavigationView {
                MealPlanView()
            }
            .tag(1)
            .tabItem {
                Label("Meal Plan", systemImage: "fork.knife")
            }
            
            NavigationView {
                WorkoutView()
            }
            .tag(2)
            .tabItem {
                Label("Workout", systemImage: "figure.walk")
            }
            
            NavigationView {
                ProfileView()
            }
            .tag(3)
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .onChange(of: selectedTab) { newTab in
            // Perform cleanup when switching tabs
            if previousTab != newTab {
                // Clear image cache if we're moving away from MealPlan tab
                if previousTab == 1 {
                    ImageCache.shared.clearCache()
                }
                previousTab = newTab
            }
        }
        .accentColor(Theme.premiumRed)
        .background(Theme.backgroundBlack)
    }
}

// Preview provider for SwiftUI canvas
#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(HealthKitManager())
            .environmentObject(UserProfileManager())
    }
}
#endif