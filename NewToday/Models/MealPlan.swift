import Foundation

enum MealType: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}

enum DietaryRestriction: String, Codable, CaseIterable {
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case nutFree = "Nut-Free"
    case none = "None"
}

struct Meal: Identifiable, Codable {
    let id: UUID
    let name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    let ingredients: [String]
    let instructions: [String]
    let imageURL: String?
    let mealType: MealType
    let dietaryInfo: [DietaryRestriction]?
    let preparationTime: Int? // in minutes
    let servingSize: String?
    let micronutrients: Micronutrients?
    let cuisineType: CuisineType?
    let difficulty: RecipeDifficulty
    let tags: [MealTag]
    
    struct Micronutrients: Codable {
        let fiber: Double
        let sugar: Double
        let sodium: Double
        let potassium: Double
        let calcium: Double
        let iron: Double
        let vitaminA: Double
        let vitaminC: Double
        let vitaminD: Double
    }
    
    enum CuisineType: String, Codable {
        case mediterranean
        case asian
        case indian
        case mexican
        case italian
        case american
        case middleEastern
        case japanese
        case thai
        case french
        case greek
        case british // Added the missing british cuisine type
    }
    
    enum RecipeDifficulty: String, Codable {
        case easy
        case medium
        case hard
    }
    
    enum MealTag: String, Codable {
        case quickAndEasy
        case mealPrep
        case highProtein
        case lowCarb
        case keto
        case paleo
        case whole30
        case budgetFriendly
        case kidFriendly
        case heartHealthy
        case diabetesFriendly
        case vegan          // Added missing vegan tag
        case vegetarian     // Added missing vegetarian tag
        case comfortFood    // Added missing comfortFood tag
    }
    
    // Custom coding keys to ensure proper encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case calories
        case protein
        case carbs
        case fats
        case ingredients
        case instructions
        case imageURL
        case mealType
        case dietaryInfo
        case preparationTime
        case servingSize
        case micronutrients
        case cuisineType
        case difficulty
        case tags
    }
}

struct DailyMealPlan: Codable {
    let date: Date
    var breakfast: Meal?
    var lunch: Meal?
    var dinner: Meal?
    var snacks: [Meal]
    
    var totalCalories: Int {
        let meals = [breakfast, lunch, dinner].compactMap { $0 }
        return meals.reduce(0) { $0 + $1.calories } + snacks.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Double {
        let meals = [breakfast, lunch, dinner].compactMap { $0 }
        return meals.reduce(0) { $0 + $1.protein } + snacks.reduce(0) { $0 + $1.protein }
    }
    
    var totalCarbs: Double {
        let meals = [breakfast, lunch, dinner].compactMap { $0 }
        return meals.reduce(0) { $0 + $1.carbs } + snacks.reduce(0) { $0 + $1.carbs }
    }
    
    var totalFats: Double {
        let meals = [breakfast, lunch, dinner].compactMap { $0 }
        return meals.reduce(0) { $0 + $1.fats } + snacks.reduce(0) { $0 + $1.fats }
    }
    
    var nutritionSummary: NutritionSummary {
        let meals = [breakfast, lunch, dinner].compactMap { $0 }
        let allMeals = meals + snacks
        
        return NutritionSummary(
            calories: totalCalories,
            macros: MacroSummary(
                protein: totalProtein,
                carbs: totalCarbs,
                fats: totalFats
            ),
            micros: calculateMicronutrients(from: allMeals)
        )
    }
    
    private func calculateMicronutrients(from meals: [Meal]) -> MicronutrientSummary {
        var summary = MicronutrientSummary()
        
        for meal in meals {
            if let micros = meal.micronutrients {
                summary.fiber += micros.fiber
                summary.sugar += micros.sugar
                summary.sodium += micros.sodium
                summary.potassium += micros.potassium
                summary.calcium += micros.calcium
                summary.iron += micros.iron
                summary.vitaminA += micros.vitaminA
                summary.vitaminC += micros.vitaminC
                summary.vitaminD += micros.vitaminD
            }
        }
        
        return summary
    }
}

struct NutritionSummary {
    let calories: Int
    let macros: MacroSummary
    let micros: MicronutrientSummary
}

struct MacroSummary {
    let protein: Double
    let carbs: Double
    let fats: Double
    
    var proteinPercentage: Double {
        let total = (protein * 4) + (carbs * 4) + (fats * 9)
        return (protein * 4) / total * 100
    }
    
    var carbsPercentage: Double {
        let total = (protein * 4) + (carbs * 4) + (fats * 9)
        return (carbs * 4) / total * 100
    }
    
    var fatsPercentage: Double {
        let total = (protein * 4) + (carbs * 4) + (fats * 9)
        return (fats * 9) / total * 100
    }
}

struct MicronutrientSummary {
    var fiber: Double = 0
    var sugar: Double = 0
    var sodium: Double = 0
    var potassium: Double = 0
    var calcium: Double = 0
    var iron: Double = 0
    var vitaminA: Double = 0
    var vitaminC: Double = 0
    var vitaminD: Double = 0
    
    func percentageOfDailyValue(for nutrient: Micronutrient) -> Double {
        switch nutrient {
        case .fiber:
            return (fiber / 25.0) * 100 // Based on 25g daily recommendation
        case .sugar:
            return (sugar / 25.0) * 100 // Based on 25g daily limit
        case .sodium:
            return (sodium / 2300.0) * 100 // Based on 2300mg daily limit
        case .potassium:
            return (potassium / 3500.0) * 100 // Based on 3500mg daily recommendation
        case .calcium:
            return (calcium / 1000.0) * 100 // Based on 1000mg daily recommendation
        case .iron:
            return (iron / 18.0) * 100 // Based on 18mg daily recommendation
        case .vitaminA:
            return (vitaminA / 900.0) * 100 // Based on 900mcg daily recommendation
        case .vitaminC:
            return (vitaminC / 90.0) * 100 // Based on 90mg daily recommendation
        case .vitaminD:
            return (vitaminD / 20.0) * 100 // Based on 20mcg daily recommendation
        }
    }
}

enum Micronutrient {
    case fiber
    case sugar
    case sodium
    case potassium
    case calcium
    case iron
    case vitaminA
    case vitaminC
    case vitaminD
}