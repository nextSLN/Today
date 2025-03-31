import Foundation
import SwiftUI

class MealService: ObservableObject {
    @Published var dailyMealPlans: [Date: DailyMealPlan] = [:]
    @Published var isGenerating = false
    
    private let userProfileManager: UserProfileManager
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
    
    init(userProfileManager: UserProfileManager) {
        self.userProfileManager = userProfileManager
        loadSampleMeals()
    }
    
    // Comprehensive meal database organized by type
    private let mealDatabase: [MealType: [Meal]] = [
        .breakfast: [
            // High Protein Breakfasts
            Meal(id: UUID(), name: "Greek Yogurt Power Bowl", calories: 380, protein: 24, carbs: 45, fats: 12,
                 ingredients: ["Greek yogurt", "Mixed berries", "Honey", "Granola", "Chia seeds", "Almonds"],
                 instructions: ["Layer greek yogurt in a bowl", "Top with berries", "Add granola and nuts", "Drizzle with honey"],
                 imageURL: "breakfast_yogurt_bowl", 
                 mealType: .breakfast,
                 dietaryInfo: [.vegetarian],
                 preparationTime: 5,
                 servingSize: "1 bowl (350g)",
                 micronutrients: Meal.Micronutrients(fiber: 6.5, sugar: 18.0, sodium: 65.0, potassium: 450.0, calcium: 280.0, iron: 2.5, vitaminA: 120.0, vitaminC: 35.0, vitaminD: 2.0),
                 cuisineType: .mediterranean,
                 difficulty: .easy,
                 tags: [.quickAndEasy, .highProtein]),
            
            // More breakfast options
        ],
        
        .lunch: [
            // Salads & Bowls
            Meal(id: UUID(), name: "Quinoa Buddha Bowl", calories: 520, protein: 24, carbs: 68, fats: 22,
                 ingredients: ["Quinoa", "Roasted chickpeas", "Sweet potato", "Kale", "Avocado", "Tahini dressing"],
                 instructions: ["Cook quinoa", "Roast chickpeas and sweet potato", "Massage kale", "Assemble bowl", "Add dressing"],
                 imageURL: "buddha_bowl",
                 mealType: .lunch,
                 dietaryInfo: [.vegan, .glutenFree],
                 preparationTime: 30,
                 servingSize: "1 bowl (450g)",
                 micronutrients: Meal.Micronutrients(fiber: 12.0, sugar: 8.0, sodium: 320.0, potassium: 820.0, calcium: 180.0, iron: 6.5, vitaminA: 380.0, vitaminC: 65.0, vitaminD: 0.0),
                 cuisineType: .mediterranean,
                 difficulty: .medium,
                 tags: [.vegan, .heartHealthy]),
            
            // More lunch options
        ],
        
        .dinner: [
            // Lean Proteins
            Meal(id: UUID(), name: "Miso Glazed Salmon", calories: 520, protein: 42, carbs: 32, fats: 24,
                 ingredients: ["Salmon fillet", "Brown rice", "Bok choy", "Miso paste", "Ginger", "Sesame oil"],
                 instructions: ["Marinate salmon", "Cook rice", "Steam bok choy", "Broil salmon", "Plate components"],
                 imageURL: "miso_salmon",
                 mealType: .dinner,
                 dietaryInfo: [.glutenFree],
                 preparationTime: 25,
                 servingSize: "1 plate (400g)",
                 micronutrients: Meal.Micronutrients(fiber: 4.0, sugar: 3.0, sodium: 580.0, potassium: 920.0, calcium: 180.0, iron: 2.8, vitaminA: 280.0, vitaminC: 45.0, vitaminD: 12.0),
                 cuisineType: .japanese,
                 difficulty: .medium,
                 tags: [.highProtein, .heartHealthy]),
            
            // More dinner options
        ],
        
        .snack: [
            // Protein Snacks
            Meal(id: UUID(), name: "Protein Energy Bites", calories: 120, protein: 8, carbs: 14, fats: 6,
                 ingredients: ["Dates", "Protein powder", "Nuts", "Cocoa powder", "Coconut flakes"],
                 instructions: ["Blend ingredients", "Form into balls", "Refrigerate"],
                 imageURL: "protein_balls",
                 mealType: .snack,
                 dietaryInfo: [.vegan, .glutenFree],
                 preparationTime: 15,
                 servingSize: "2 balls (40g)",
                 micronutrients: Meal.Micronutrients(fiber: 3.0, sugar: 8.0, sodium: 45.0, potassium: 180.0, calcium: 40.0, iron: 1.2, vitaminA: 0.0, vitaminC: 0.0, vitaminD: 0.0),
                 cuisineType: .american,
                 difficulty: .easy,
                 tags: [.mealPrep, .highProtein]),
            
            // More snack options
        ]
    ]
    
    func getMeal(for type: MealType, on date: Date) -> Meal? {
        guard let plan = dailyMealPlans[date] else { return nil }
        
        switch type {
        case .breakfast:
            return plan.breakfast
        case .lunch:
            return plan.lunch
        case .dinner:
            return plan.dinner
        case .snack:
            return plan.snacks.first
        }
    }
    
    func getDailyMealPlan(for date: Date) -> DailyMealPlan? {
        return dailyMealPlans[date]
    }
    
    func generateMeal(for type: MealType, on date: Date) {
        isGenerating = true
        
        var mealPlan = dailyMealPlans[date] ?? DailyMealPlan(date: date, breakfast: nil, lunch: nil, dinner: nil, snacks: [])
        
        // Generate meal based on user preferences and dietary restrictions
        let newMeal = generatePersonalizedMeal(for: type)
        
        // Update the meal plan with the new meal
        switch type {
        case .breakfast:
            mealPlan.breakfast = newMeal
        case .lunch:
            mealPlan.lunch = newMeal
        case .dinner:
            mealPlan.dinner = newMeal
        case .snack:
            if mealPlan.snacks.isEmpty {
                mealPlan.snacks.append(newMeal)
            } else {
                mealPlan.snacks[0] = newMeal
            }
        }
        
        // Recalculate totals in the meal plan
        dailyMealPlans[date] = mealPlan
        
        isGenerating = false
    }
    
    func generateFullDayMealPlan(for date: Date) {
        MealType.allCases.forEach { type in
            generateMeal(for: type, on: date)
        }
    }
    
    private func generatePersonalizedMeal(for type: MealType) -> Meal {
        // Get user profile for personalization
        guard let profile = userProfileManager.userProfile else {
            return sampleMeals(for: type).randomElement()!
        }

        // Filter meals based on user's dietary restrictions
        var eligibleMeals = sampleMeals(for: type).filter { meal in
            // Check for vegetarian restrictions
            if let restrictions = profile.dietaryRestrictions, 
               restrictions.contains(.vegetarian),
               meal.name.lowercased().contains("chicken") || meal.name.lowercased().contains("beef") {
                return false
            }
            
            // Check for vegan restrictions
            if let restrictions = profile.dietaryRestrictions,
               restrictions.contains(.vegan),
               meal.name.lowercased().contains("chicken") || 
               meal.name.lowercased().contains("beef") || 
               meal.name.lowercased().contains("egg") {
                return false
            }
            
            return true
        }
        
        if eligibleMeals.isEmpty {
            eligibleMeals = sampleMeals(for: type)
        }
        
        // Adjust calorie content based on user's goals
        let meal = eligibleMeals.randomElement()!
        var adjustedMeal = meal
        
        // Adjust meal based on fitness goals
        if let firstGoal = profile.fitnessGoals.first {
            switch firstGoal {
            case .weightLoss:
                adjustedMeal.calories = Int(Double(meal.calories) * 0.85)
                adjustedMeal.fats = meal.fats * 0.8
            case .muscleGain:
                adjustedMeal.calories = Int(Double(meal.calories) * 1.1)
                adjustedMeal.protein = meal.protein * 1.3
            default:
                break // Keep original values
            }
        }
        
        return adjustedMeal
    }
    
    // Sample meals for quick testing
    private func loadSampleMeals() {
        // Generate a meal plan for today
        let today = Date()
        
        // Create a meal plan with sample meals
        let breakfast = sampleMeals(for: .breakfast).randomElement()!
        let lunch = sampleMeals(for: .lunch).randomElement()!
        let dinner = sampleMeals(for: .dinner).randomElement()!
        let snack = sampleMeals(for: .snack).randomElement()!
        
        let mealPlan = DailyMealPlan(
            date: today,
            breakfast: breakfast,
            lunch: lunch,
            dinner: dinner,
            snacks: [snack]
        )
        
        dailyMealPlans[today] = mealPlan
    }
    
    private func sampleMeals(for type: MealType) -> [Meal] {
        return mealDatabase[type] ?? [
            // Default meal if database entry not found
            Meal(
                id: UUID(),
                name: "Default Meal",
                calories: 300,
                protein: 15,
                carbs: 30,
                fats: 10,
                ingredients: ["Ingredient 1", "Ingredient 2"],
                instructions: ["Step 1", "Step 2"],
                imageURL: nil,
                mealType: type,
                dietaryInfo: nil,
                preparationTime: 15,
                servingSize: "1 serving",
                micronutrients: nil,
                cuisineType: .american,
                difficulty: .easy,
                tags: [.quickAndEasy]
            )
        ]
    }
}