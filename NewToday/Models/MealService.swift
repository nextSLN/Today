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
            Meal(
                id: UUID(),
                name: "Greek Yogurt Power Bowl",
                calories: 380,
                protein: 24,
                carbs: 45,
                fats: 12,
                ingredients: ["Greek yogurt", "Mixed berries", "Honey", "Granola", "Chia seeds", "Almonds"],
                instructions: [
                    "Layer Greek yogurt in a bowl",
                    "Add mixed berries",
                    "Sprinkle granola and chia seeds",
                    "Top with sliced almonds",
                    "Drizzle with honey"
                ],
                imageURL: "https://images.unsplash.com/photo-1611868862899-07c2f7d8e2e5",  // Updated to correct Greek yogurt bowl image
                mealType: .breakfast,
                dietaryInfo: [.vegetarian],
                preparationTime: 5,
                servingSize: "1 bowl (350g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 6.5, sugar: 18.0, sodium: 65.0,
                    potassium: 450.0, calcium: 280.0, iron: 2.5,
                    vitaminA: 120.0, vitaminC: 35.0, vitaminD: 2.0
                ),
                cuisineType: .mediterranean,
                difficulty: .easy,
                tags: [.quickAndEasy, .highProtein]
            ),
            
            Meal(
                id: UUID(),
                name: "Protein Oatmeal Bowl",
                calories: 420,
                protein: 28,
                carbs: 52,
                fats: 14,
                ingredients: [
                    "Rolled oats",
                    "Whey protein powder",
                    "Banana",
                    "Almond milk",
                    "Peanut butter",
                    "Cinnamon"
                ],
                instructions: [
                    "Cook oats with almond milk",
                    "Stir in protein powder",
                    "Top with sliced banana",
                    "Add a dollop of peanut butter",
                    "Sprinkle with cinnamon"
                ],
                imageURL: "https://images.unsplash.com/photo-1584263347416-86c87812edad",  // Updated to correct oatmeal image
                mealType: .breakfast,
                dietaryInfo: [.vegetarian],
                preparationTime: 10,
                servingSize: "1 bowl (400g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 8.0, sugar: 12.0, sodium: 120.0,
                    potassium: 520.0, calcium: 320.0, iron: 3.8,
                    vitaminA: 80.0, vitaminC: 12.0, vitaminD: 1.5
                ),
                cuisineType: .american,
                difficulty: .easy,
                tags: [.highProtein, .quickAndEasy]
            ),
            
            Meal(
                id: UUID(),
                name: "Vegan Tofu Scramble",
                calories: 320,
                protein: 22,
                carbs: 28,
                fats: 16,
                ingredients: [
                    "Firm tofu",
                    "Nutritional yeast",
                    "Bell peppers",
                    "Spinach",
                    "Turmeric",
                    "Black salt (kala namak)",
                    "Whole grain toast"
                ],
                instructions: [
                    "Crumble tofu and season with turmeric and black salt",
                    "Sauté vegetables",
                    "Combine tofu and vegetables",
                    "Sprinkle nutritional yeast",
                    "Serve with toast"
                ],
                imageURL: "https://images.unsplash.com/photo-1648043067307-824b13c1daf3",  // Updated to correct tofu scramble image
                mealType: .breakfast,
                dietaryInfo: [.vegan, .vegetarian],
                preparationTime: 15,
                servingSize: "1 plate (300g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 6.0, sugar: 4.0, sodium: 380.0,
                    potassium: 450.0, calcium: 250.0, iron: 4.5,
                    vitaminA: 220.0, vitaminC: 45.0, vitaminD: 0.0
                ),
                cuisineType: .american,
                difficulty: .medium,
                tags: [.vegan, .highProtein]
            ),
            
            Meal(
                id: UUID(),
                name: "Keto Breakfast Plate",
                calories: 450,
                protein: 28,
                carbs: 8,
                fats: 35,
                ingredients: [
                    "Eggs",
                    "Avocado",
                    "Bacon",
                    "Spinach",
                    "Cherry tomatoes",
                    "Olive oil"
                ],
                instructions: [
                    "Cook bacon until crispy",
                    "Fry eggs in the remaining bacon fat",
                    "Slice avocado",
                    "Sauté spinach with olive oil",
                    "Arrange on plate with cherry tomatoes"
                ],
                imageURL: "https://images.unsplash.com/photo-1615937722923-67f6deaf2cc9",  // Updated to correct keto breakfast image
                mealType: .breakfast,
                dietaryInfo: [.glutenFree],
                preparationTime: 15,
                servingSize: "1 plate (350g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 7.0, sugar: 2.0, sodium: 580.0,
                    potassium: 650.0, calcium: 80.0, iron: 3.5,
                    vitaminA: 180.0, vitaminC: 25.0, vitaminD: 2.8
                ),
                cuisineType: .american,
                difficulty: .easy,
                tags: [.keto, .highProtein]
            ),
            
            Meal(
                id: UUID(),
                name: "Smoothie Bowl",
                calories: 340,
                protein: 16,
                carbs: 52,
                fats: 10,
                ingredients: [
                    "Frozen açai packet",
                    "Banana",
                    "Mixed berries",
                    "Plant-based protein powder",
                    "Almond milk",
                    "Granola",
                    "Coconut flakes"
                ],
                instructions: [
                    "Blend açai, banana, berries, protein powder, and almond milk",
                    "Pour into bowl",
                    "Top with granola and coconut flakes"
                ],
                imageURL: "https://images.unsplash.com/photo-1626790680787-de5e9a8c45c2",  // Updated to correct smoothie bowl image
                mealType: .breakfast,
                dietaryInfo: [.vegan, .vegetarian],
                preparationTime: 10,
                servingSize: "1 bowl (400g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 9.0, sugar: 24.0, sodium: 120.0,
                    potassium: 580.0, calcium: 220.0, iron: 4.2,
                    vitaminA: 150.0, vitaminC: 65.0, vitaminD: 0.0
                ),
                cuisineType: .american,
                difficulty: .easy,
                tags: [.vegan, .quickAndEasy]
            ),
            
            Meal(
                id: UUID(),
                name: "Japanese Breakfast Bowl",
                calories: 380,
                protein: 22,
                carbs: 48,
                fats: 12,
                ingredients: [
                    "Brown rice",
                    "Grilled salmon",
                    "Miso soup",
                    "Natto",
                    "Tamagoyaki",
                    "Pickled vegetables",
                    "Nori"
                ],
                instructions: [
                    "Cook rice and prepare miso soup",
                    "Grill salmon",
                    "Make tamagoyaki (rolled omelette)",
                    "Arrange all components in bowl",
                    "Serve with pickles and nori"
                ],
                imageURL: "https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d",  // This one is correct
                mealType: .breakfast,
                dietaryInfo: [.glutenFree],
                preparationTime: 25,
                servingSize: "1 bowl (400g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 4.0, sugar: 2.0, sodium: 850.0,
                    potassium: 580.0, calcium: 120.0, iron: 3.2,
                    vitaminA: 180.0, vitaminC: 15.0, vitaminD: 8.0
                ),
                cuisineType: .japanese,
                difficulty: .hard,
                tags: [.highProtein, .heartHealthy]
            )
        ],
        
        .lunch: [
            Meal(
                id: UUID(),
                name: "Mediterranean Quinoa Bowl",
                calories: 520,
                protein: 24,
                carbs: 68,
                fats: 22,
                ingredients: [
                    "Quinoa",
                    "Chickpeas",
                    "Cherry tomatoes",
                    "Cucumber",
                    "Kalamata olives",
                    "Feta cheese",
                    "Extra virgin olive oil",
                    "Lemon juice"
                ],
                instructions: [
                    "Cook quinoa according to package instructions",
                    "Combine with chopped vegetables",
                    "Add chickpeas and olives",
                    "Crumble feta cheese on top",
                    "Dress with olive oil and lemon juice"
                ],
                imageURL: "https://images.unsplash.com/photo-1593560367362-c6f4c185c380",  // Updated to correct quinoa bowl image
                mealType: .lunch,
                dietaryInfo: [.vegetarian],
                preparationTime: 20,
                servingSize: "1 bowl (450g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 12.0, sugar: 8.0, sodium: 320.0,
                    potassium: 820.0, calcium: 180.0, iron: 6.5,
                    vitaminA: 380.0, vitaminC: 65.0, vitaminD: 0.0
                ),
                cuisineType: .mediterranean,
                difficulty: .easy,
                tags: [.vegetarian, .heartHealthy]
            ),
            
            Meal(
                id: UUID(),
                name: "Asian Chicken Salad",
                calories: 450,
                protein: 35,
                carbs: 38,
                fats: 18,
                ingredients: [
                    "Grilled chicken breast",
                    "Mixed greens",
                    "Mandarin oranges",
                    "Edamame",
                    "Almonds",
                    "Sesame ginger dressing"
                ],
                instructions: [
                    "Grill and slice chicken",
                    "Combine greens and vegetables",
                    "Add mandarin oranges and almonds",
                    "Top with chicken",
                    "Drizzle with dressing"
                ],
                imageURL: "https://images.unsplash.com/photo-1547496502-affa22d38842",  // Updated to correct Asian salad image
                mealType: .lunch,
                dietaryInfo: [.nutFree],
                preparationTime: 25,
                servingSize: "1 plate (380g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 8.0, sugar: 12.0, sodium: 420.0,
                    potassium: 780.0, calcium: 120.0, iron: 3.2,
                    vitaminA: 280.0, vitaminC: 75.0, vitaminD: 0.0
                ),
                cuisineType: .asian,
                difficulty: .medium,
                tags: [.highProtein, .heartHealthy]
            ),
            
            Meal(
                id: UUID(),
                name: "Poke Bowl",
                calories: 550,
                protein: 32,
                carbs: 65,
                fats: 18,
                ingredients: [
                    "Sushi grade tuna",
                    "Brown rice",
                    "Edamame",
                    "Cucumber",
                    "Carrots",
                    "Avocado",
                    "Seaweed",
                    "Soy sauce",
                    "Sesame oil"
                ],
                instructions: [
                    "Cube tuna",
                    "Cook brown rice",
                    "Slice vegetables",
                    "Assemble in bowl",
                    "Dress with soy sauce and sesame oil"
                ],
                imageURL: "https://images.unsplash.com/photo-1582450871972-ab5ca641643d",  // Updated to proper poke bowl image
                mealType: .lunch,
                dietaryInfo: [.glutenFree, .dairyFree],
                preparationTime: 20,
                servingSize: "1 bowl (450g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 8.0, sugar: 4.0, sodium: 620.0,
                    potassium: 780.0, calcium: 120.0, iron: 3.8,
                    vitaminA: 280.0, vitaminC: 45.0, vitaminD: 3.5
                ),
                cuisineType: .japanese,
                difficulty: .medium,
                tags: [.highProtein, .heartHealthy]
            ),
            
            Meal(
                id: UUID(),
                name: "Mexican Bean Bowl",
                calories: 480,
                protein: 22,
                carbs: 72,
                fats: 16,
                ingredients: [
                    "Black beans",
                    "Brown rice",
                    "Corn",
                    "Bell peppers",
                    "Red onion",
                    "Avocado",
                    "Lime",
                    "Cilantro",
                    "Salsa"
                ],
                instructions: [
                    "Cook rice and beans",
                    "Sauté vegetables",
                    "Assemble in bowl",
                    "Top with avocado and salsa",
                    "Garnish with cilantro and lime"
                ],
                imageURL: "https://images.unsplash.com/photo-1513442542250-854d436a73f2",  // This one is correct
                mealType: .lunch,
                dietaryInfo: [.vegan, .vegetarian, .glutenFree],
                preparationTime: 25,
                servingSize: "1 bowl (400g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 12.0, sugar: 6.0, sodium: 380.0,
                    potassium: 820.0, calcium: 140.0, iron: 4.8,
                    vitaminA: 320.0, vitaminC: 85.0, vitaminD: 0.0
                ),
                cuisineType: .mexican,
                difficulty: .easy,
                tags: [.vegan, .heartHealthy]
            ),
            
            Meal(
                id: UUID(),
                name: "Mediterranean Mezze Plate",
                calories: 450,
                protein: 15,
                carbs: 48,
                fats: 25,
                ingredients: [
                    "Hummus",
                    "Baba ganoush",
                    "Falafel",
                    "Pita bread",
                    "Tabbouleh",
                    "Olives",
                    "Fresh vegetables"
                ],
                instructions: [
                    "Prepare or arrange hummus and baba ganoush",
                    "Heat falafel",
                    "Make tabbouleh",
                    "Arrange all items on plate",
                    "Serve with warm pita"
                ],
                imageURL: "https://images.unsplash.com/photo-1542345812-d98b5cd6cf98",  // Updated to proper mezze plate image
                mealType: .lunch,
                dietaryInfo: [.vegan, .vegetarian],
                preparationTime: 20,
                servingSize: "1 plate (400g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 12.0, sugar: 6.0, sodium: 580.0,
                    potassium: 620.0, calcium: 150.0, iron: 5.8,
                    vitaminA: 280.0, vitaminC: 45.0, vitaminD: 0.0
                ),
                cuisineType: .mediterranean,
                difficulty: .easy,
                tags: [.vegan, .mealPrep]
            )
        ],
        
        .dinner: [
            Meal(
                id: UUID(),
                name: "Miso Glazed Salmon",
                calories: 520,
                protein: 42,
                carbs: 32,
                fats: 24,
                ingredients: [
                    "Salmon fillet",
                    "Miso paste",
                    "Brown rice",
                    "Bok choy",
                    "Sesame oil",
                    "Ginger",
                    "Soy sauce"
                ],
                instructions: [
                    "Prepare miso glaze",
                    "Marinate salmon",
                    "Cook brown rice",
                    "Steam bok choy",
                    "Grill or bake salmon",
                    "Serve with vegetables"
                ],
                imageURL: "https://images.unsplash.com/photo-1559848099-ab3f48adb092",  // Updated to correct salmon image
                mealType: .dinner,
                dietaryInfo: [.glutenFree],
                preparationTime: 30,
                servingSize: "1 plate (400g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 4.0, sugar: 3.0, sodium: 580.0,
                    potassium: 920.0, calcium: 180.0, iron: 2.8,
                    vitaminA: 280.0, vitaminC: 45.0, vitaminD: 12.0
                ),
                cuisineType: .japanese,
                difficulty: .medium,
                tags: [.highProtein, .heartHealthy]
            ),
            
            Meal(
                id: UUID(),
                name: "Vegan Buddha Bowl",
                calories: 480,
                protein: 18,
                carbs: 62,
                fats: 20,
                ingredients: [
                    "Sweet potato",
                    "Quinoa",
                    "Kale",
                    "Chickpeas",
                    "Avocado",
                    "Tahini dressing"
                ],
                instructions: [
                    "Roast sweet potato chunks",
                    "Cook quinoa",
                    "Massage kale with olive oil",
                    "Season and roast chickpeas",
                    "Assemble bowl",
                    "Top with tahini dressing"
                ],
                imageURL: "https://images.unsplash.com/photo-1546007600-8035c4a9e917",  // Updated to correct buddha bowl image
                mealType: .dinner,
                dietaryInfo: [.vegan, .glutenFree],
                preparationTime: 35,
                servingSize: "1 bowl (450g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 14.0, sugar: 9.0, sodium: 320.0,
                    potassium: 880.0, calcium: 160.0, iron: 5.8,
                    vitaminA: 420.0, vitaminC: 85.0, vitaminD: 0.0
                ),
                cuisineType: .mediterranean,
                difficulty: .medium,
                tags: [.vegan, .heartHealthy]
            ),
            
            Meal(
                id: UUID(),
                name: "Mediterranean Grilled Chicken",
                calories: 480,
                protein: 45,
                carbs: 35,
                fats: 20,
                ingredients: [
                    "Chicken breast",
                    "Quinoa",
                    "Greek salad",
                    "Tzatziki",
                    "Lemon",
                    "Olive oil",
                    "Mediterranean herbs"
                ],
                instructions: [
                    "Marinate chicken in herbs and lemon",
                    "Grill chicken",
                    "Cook quinoa",
                    "Prepare Greek salad",
                    "Serve with tzatziki"
                ],
                imageURL: "https://images.unsplash.com/photo-1598515214211-89d3c73ae83b",  // Updated to correct grilled chicken image
                mealType: .dinner,
                dietaryInfo: [.glutenFree],
                preparationTime: 35,
                servingSize: "1 plate (400g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 6.0, sugar: 4.0, sodium: 480.0,
                    potassium: 720.0, calcium: 150.0, iron: 3.8,
                    vitaminA: 220.0, vitaminC: 45.0, vitaminD: 0.2
                ),
                cuisineType: .mediterranean,
                difficulty: .medium,
                tags: [.highProtein, .heartHealthy]
            ),
            
            Meal(
                id: UUID(),
                name: "Indian Lentil Curry",
                calories: 420,
                protein: 18,
                carbs: 58,
                fats: 16,
                ingredients: [
                    "Red lentils",
                    "Coconut milk",
                    "Tomatoes",
                    "Onion",
                    "Garlic",
                    "Ginger",
                    "Indian spices",
                    "Brown rice"
                ],
                instructions: [
                    "Cook lentils with spices",
                    "Prepare curry sauce",
                    "Cook rice",
                    "Combine and simmer",
                    "Garnish with cilantro"
                ],
                imageURL: "https://images.unsplash.com/photo-1585937421612-70a008356fbe",  // This one is correct
                mealType: .dinner,
                dietaryInfo: [.vegan, .vegetarian, .glutenFree],
                preparationTime: 40,
                servingSize: "1 bowl (450g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 12.0, sugar: 6.0, sodium: 420.0,
                    potassium: 680.0, calcium: 120.0, iron: 6.5,
                    vitaminA: 280.0, vitaminC: 35.0, vitaminD: 0.0
                ),
                cuisineType: .indian,
                difficulty: .medium,
                tags: [.vegan, .budgetFriendly]
            ),
            
            Meal(
                id: UUID(),
                name: "Thai Green Curry",
                calories: 520,
                protein: 28,
                carbs: 42,
                fats: 28,
                ingredients: [
                    "Chicken breast",
                    "Coconut milk",
                    "Green curry paste",
                    "Thai eggplant",
                    "Bamboo shoots",
                    "Thai basil",
                    "Jasmine rice"
                ],
                instructions: [
                    "Cook rice",
                    "Prepare curry with coconut milk and paste",
                    "Add chicken and vegetables",
                    "Simmer until cooked",
                    "Garnish with Thai basil"
                ],
                imageURL: "https://images.unsplash.com/photo-1548943487-a2e4e43b4853",  // Updated to proper Thai curry image
                mealType: .dinner,
                dietaryInfo: [.glutenFree],
                preparationTime: 35,
                servingSize: "1 bowl (450g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 6.0, sugar: 8.0, sodium: 720.0,
                    potassium: 650.0, calcium: 85.0, iron: 4.2,
                    vitaminA: 220.0, vitaminC: 45.0, vitaminD: 0.0
                ),
                cuisineType: .thai,
                difficulty: .medium,
                tags: [.highProtein, .comfortFood]
            )
        ],
        
        .snack: [
            Meal(
                id: UUID(),
                name: "Protein Energy Bites",
                calories: 120,
                protein: 8,
                carbs: 14,
                fats: 6,
                ingredients: [
                    "Dates",
                    "Protein powder",
                    "Almond butter",
                    "Chia seeds",
                    "Dark chocolate chips"
                ],
                instructions: [
                    "Process dates until smooth",
                    "Mix in remaining ingredients",
                    "Form into balls",
                    "Refrigerate for 30 minutes"
                ],
                imageURL: "https://images.unsplash.com/photo-1582319990242-6476581619b6",  // Updated to correct energy bites image
                mealType: .snack,
                dietaryInfo: [.vegan, .glutenFree],
                preparationTime: 15,
                servingSize: "2 balls (40g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 3.0, sugar: 8.0, sodium: 45.0,
                    potassium: 180.0, calcium: 40.0, iron: 1.2,
                    vitaminA: 0.0, vitaminC: 0.0, vitaminD: 0.0
                ),
                cuisineType: .american,
                difficulty: .easy,
                tags: [.vegan, .highProtein]
            ),
            
            Meal(
                id: UUID(),
                name: "Greek Yogurt Parfait",
                calories: 180,
                protein: 12,
                carbs: 22,
                fats: 5,
                ingredients: [
                    "Greek yogurt",
                    "Mixed berries",
                    "Granola",
                    "Honey"
                ],
                instructions: [
                    "Layer yogurt in a glass",
                    "Add berries",
                    "Top with granola",
                    "Drizzle with honey"
                ],
                imageURL: "https://images.unsplash.com/photo-1488477181946-6428a0291777",  // This one is correct
                mealType: .snack,
                dietaryInfo: [.vegetarian],
                preparationTime: 5,
                servingSize: "1 parfait (200g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 3.0, sugar: 14.0, sodium: 35.0,
                    potassium: 220.0, calcium: 180.0, iron: 0.8,
                    vitaminA: 45.0, vitaminC: 22.0, vitaminD: 0.0
                ),
                cuisineType: .mediterranean,
                difficulty: .easy,
                tags: [.quickAndEasy, .highProtein]
            ),
            
            Meal(
                id: UUID(),
                name: "Trail Mix",
                calories: 160,
                protein: 6,
                carbs: 18,
                fats: 8,
                ingredients: [
                    "Mixed nuts",
                    "Dried cranberries",
                    "Dark chocolate chips",
                    "Pumpkin seeds"
                ],
                instructions: [
                    "Mix all ingredients",
                    "Portion into servings"
                ],
                imageURL: "https://images.unsplash.com/photo-1594745561149-2211ca8c5d98",  // Updated to correct trail mix image
                mealType: .snack,
                dietaryInfo: [.vegan, .glutenFree],
                preparationTime: 2,
                servingSize: "1/4 cup (30g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 2.5, sugar: 8.0, sodium: 45.0,
                    potassium: 180.0, calcium: 40.0, iron: 1.8,
                    vitaminA: 0.0, vitaminC: 2.0, vitaminD: 0.0
                ),
                cuisineType: .american,
                difficulty: .easy,
                tags: [.quickAndEasy, .mealPrep]
            ),
            
            Meal(
                id: UUID(),
                name: "Hummus with Vegetables",
                calories: 150,
                protein: 6,
                carbs: 15,
                fats: 9,
                ingredients: [
                    "Hummus",
                    "Carrot sticks",
                    "Cucumber slices",
                    "Bell pepper strips",
                    "Cherry tomatoes"
                ],
                instructions: [
                    "Arrange vegetables on plate",
                    "Serve with hummus"
                ],
                imageURL: "https://images.unsplash.com/photo-1505576399279-565b52d4ac71",  // Updated to correct hummus and vegetables image
                mealType: .snack,
                dietaryInfo: [.vegan, .vegetarian, .glutenFree],
                preparationTime: 5,
                servingSize: "1 portion (120g)",
                micronutrients: Meal.Micronutrients(
                    fiber: 4.0, sugar: 6.0, sodium: 280.0,
                    potassium: 320.0, calcium: 45.0, iron: 1.2,
                    vitaminA: 180.0, vitaminC: 65.0, vitaminD: 0.0
                ),
                cuisineType: .mediterranean,
                difficulty: .easy,
                tags: [.vegan, .quickAndEasy]
            ),
            
            Meal(
                id: UUID(),
                name: "Protein Recovery Smoothie",
                calories: 320,
                protein: 24,
                carbs: 45,
                fats: 8,
                ingredients: [
                    "Whey protein powder",
                    "Banana",
                    "Spinach",
                    "Greek yogurt",
                    "Almond milk",
                    "Chia seeds",
                    "Honey"
                ],
                instructions: [
                    "Add all ingredients to blender",
                    "Blend until smooth",
                    "Add ice if desired"
                ],
                imageURL: "https://images.unsplash.com/photo-1506432889746-9333e144f461",  // Updated to proper smoothie image
                mealType: .snack,
                dietaryInfo: [.vegetarian],
                preparationTime: 5,
                servingSize: "1 glass (400ml)",
                micronutrients: Meal.Micronutrients(
                    fiber: 5.0, sugar: 22.0, sodium: 180.0,
                    potassium: 720.0, calcium: 380.0, iron: 2.8,
                    vitaminA: 180.0, vitaminC: 35.0, vitaminD: 1.2
                ),
                cuisineType: .american,
                difficulty: .easy,
                tags: [.quickAndEasy, .highProtein]
            )
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
        
        // Store old meal URL to clear from cache
        let oldMeal = getMeal(for: type, on: date)
        let oldImageURL = oldMeal?.imageURL
        
        var mealPlan = dailyMealPlans[date] ?? DailyMealPlan(date: date, breakfast: nil, lunch: nil, dinner: nil, snacks: [])
        
        // Generate meal based on user preferences and dietary restrictions
        let newMeal = generatePersonalizedMeal(for: type)
        
        // Clear old image from cache
        if let urlString = oldImageURL {
            MealPlanView.imageCache.removeObject(forKey: urlString as NSString)
        }
        
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
        // Clear cache for all existing meals
        if let plan = dailyMealPlans[date] {
            [plan.breakfast, plan.lunch, plan.dinner]
                .compactMap { $0?.imageURL }
                .forEach { MealPlanView.imageCache.removeObject(forKey: $0 as NSString) }
            
            plan.snacks
                .compactMap { $0.imageURL }
                .forEach { MealPlanView.imageCache.removeObject(forKey: $0 as NSString) }
        }
        
        MealType.allCases.forEach { type in
            generateMeal(for: type, on: date)
        }
    }
    
    private func generatePersonalizedMeal(for type: MealType) -> Meal {
        guard let profile = userProfileManager.userProfile else {
            return sampleMeals(for: type).randomElement()!
        }

        // Filter meals based on dietary restrictions and preferences
        var eligibleMeals = sampleMeals(for: type).filter { meal in
            // Check dietary restrictions
            if let restrictions = profile.dietaryRestrictions,
               !restrictions.isEmpty {
                if let mealDietInfo = meal.dietaryInfo {
                    // Handle vegetarian restriction
                    if restrictions.contains(.vegetarian) && !mealDietInfo.contains(.vegetarian) {
                        return false
                    }
                    // Handle vegan restriction
                    if restrictions.contains(.vegan) && !mealDietInfo.contains(.vegan) {
                        return false
                    }
                    // Handle gluten-free restriction
                    if restrictions.contains(.glutenFree) && !mealDietInfo.contains(.glutenFree) {
                        return false
                    }
                    // Handle dairy-free restriction
                    if restrictions.contains(.dairyFree) && !mealDietInfo.contains(.dairyFree) {
                        return false
                    }
                }
            }
            return true
        }
        
        if eligibleMeals.isEmpty {
            eligibleMeals = sampleMeals(for: type)
        }
        
        // Select a meal and adjust it based on user's goals and needs
        let meal = eligibleMeals.randomElement()!
        var adjustedMeal = meal
        
        // Adjust portions based on daily calorie needs
        let calorieAdjustmentFactor = Double(profile.dailyCalorieNeeds) / 2000.0
        
        // Adjust based on fitness goals
        if let primaryGoal = profile.fitnessGoals.first {
            switch primaryGoal {
            case .weightLoss:
                adjustedMeal.calories = Int(Double(meal.calories) * 0.85 * calorieAdjustmentFactor)
                adjustedMeal.carbs = meal.carbs * 0.8
                adjustedMeal.fats = meal.fats * 0.8
                adjustedMeal.protein = meal.protein * 1.2 // Maintain protein for muscle preservation
                
            case .muscleGain:
                adjustedMeal.calories = Int(Double(meal.calories) * 1.2 * calorieAdjustmentFactor)
                adjustedMeal.protein = meal.protein * 1.5
                adjustedMeal.carbs = meal.carbs * 1.3
                adjustedMeal.fats = meal.fats * 1.1
                
            case .maintenance:
                adjustedMeal.calories = Int(Double(meal.calories) * calorieAdjustmentFactor)
                
            case .endurance:
                adjustedMeal.calories = Int(Double(meal.calories) * 1.1 * calorieAdjustmentFactor)
                adjustedMeal.carbs = meal.carbs * 1.4
                adjustedMeal.protein = meal.protein * 1.2
                
            default:
                adjustedMeal.calories = Int(Double(meal.calories) * calorieAdjustmentFactor)
            }
        }
        
        // Adjust based on activity level
        switch profile.activityLevel {
        case .veryActive, .extraActive:
            adjustedMeal.calories = Int(Double(adjustedMeal.calories) * 1.1)
        case .sedentary:
            adjustedMeal.calories = Int(Double(adjustedMeal.calories) * 0.9)
        default:
            break
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
