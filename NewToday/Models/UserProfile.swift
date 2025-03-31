import Foundation

struct UserProfile: Codable {
    var name: String
    var age: Int
    var gender: Gender
    var height: Double // in cm
    var weight: Double // in kg
    var activityLevel: ActivityLevel
    var fitnessGoals: [FitnessGoal]
    var dietaryRestrictions: [DietaryRestriction]?
    var allergies: [String]?
    var medicalConditions: [MedicalCondition]?
    var sleepGoal: Int // in hours
    var waterGoal: Double // in liters
    var dailyCalorieNeeds: Int
    var macroTargets: MacroTargets
    var preferredWorkoutTypes: [WorkoutType]
    var workoutFrequency: WorkoutFrequency
    var measurementPreference: MeasurementPreference
    var notificationPreferences: NotificationPreferences
    var lastUpdateDate: Date

    enum Gender: String, Codable {
        case male, female, other
    }

    enum ActivityLevel: String, Codable, CaseIterable {
        case sedentary = "Sedentary"
        case lightlyActive = "Lightly Active"
        case moderatelyActive = "Moderately Active"
        case veryActive = "Very Active"
        case extraActive = "Extra Active"
        
        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .lightlyActive: return 1.375
            case .moderatelyActive: return 1.55
            case .veryActive: return 1.725
            case .extraActive: return 1.9
            }
        }
    }

    enum FitnessGoal: String, Codable, CaseIterable {
        case weightLoss = "Weight Loss"
        case muscleGain = "Muscle Gain"
        case maintenance = "Maintenance"
        case endurance = "Endurance"
        case flexibility = "Flexibility"
        case strength = "Strength"
        case stressReduction = "Stress Reduction"
        case betterSleep = "Better Sleep"
    }

    enum WorkoutType: String, Codable, CaseIterable {
        case running = "Running"
        case cycling = "Cycling"
        case swimming = "Swimming"
        case weightTraining = "Weight Training"
        case yoga = "Yoga"
        case hiit = "HIIT"
        case pilates = "Pilates"
        case boxing = "Boxing"
        case climbing = "Climbing"
        case crossfit = "CrossFit"
    }

    enum WorkoutFrequency: String, Codable, CaseIterable {
        case oneToTwo = "1-2 times per week"
        case threeToFour = "3-4 times per week"
        case fiveToSix = "5-6 times per week"
        case daily = "Daily"
        
        var daysPerWeek: Int {
            switch self {
            case .oneToTwo: return 2
            case .threeToFour: return 4
            case .fiveToSix: return 6
            case .daily: return 7
            }
        }
    }

    enum MedicalCondition: String, Codable {
        case diabetes
        case hypertension
        case heartDisease
        case asthma
        case arthritis
        case osteoporosis
        case none
    }

    enum MeasurementPreference: String, Codable {
        case metric
        case imperial
    }

    struct MacroTargets: Codable {
        var protein: Double // percentage
        var carbs: Double // percentage
        var fats: Double // percentage
    }

    struct NotificationPreferences: Codable {
        var workoutReminders: Bool
        var mealReminders: Bool
        var waterReminders: Bool
        var sleepReminders: Bool
        var progressUpdates: Bool
        var reminderTimes: [ReminderType: [Date]]
    }

    enum ReminderType: String, Codable {
        case workout
        case meal
        case water
        case sleep
        case progress
    }

    // Computed Properties
    var bmi: Double {
        return weight / ((height / 100) * (height / 100))
    }

    var bmr: Double {
        let ageConstant: Double
        let weightConstant: Double
        let heightConstant: Double
        let baseConstant: Double

        switch gender {
        case .male:
            ageConstant = 5
            weightConstant = 10
            heightConstant = 6.25
            baseConstant = 5
        case .female:
            ageConstant = 5.4
            weightConstant = 9.2
            heightConstant = 3.1
            baseConstant = 161
        case .other:
            // Use average of male and female constants
            ageConstant = 5.2
            weightConstant = 9.6
            heightConstant = 4.7
            baseConstant = 83
        }

        return (weightConstant * weight) + (heightConstant * height) - (ageConstant * Double(age)) + baseConstant
    }

    var tdee: Double {
        return bmr * activityLevel.multiplier
    }

    // Methods for calculating personalized targets
    func calculateCalorieTarget(for goal: FitnessGoal) -> Int {
        let base = tdee
        switch goal {
        case .weightLoss:
            return Int(base * 0.8) // 20% deficit
        case .muscleGain:
            return Int(base * 1.1) // 10% surplus
        default:
            return Int(base)
        }
    }

    func calculateProteinTarget() -> Double {
        let multiplier: Double
        switch fitnessGoals.first {
        case .muscleGain:
            multiplier = 2.0 // 2g per kg of body weight
        case .weightLoss:
            multiplier = 2.2 // Higher protein for preservation
        default:
            multiplier = 1.6
        }
        return weight * multiplier
    }

    // Initialize with default values
    init(name: String, age: Int, gender: Gender, height: Double, weight: Double) {
        self.name = name
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
        self.activityLevel = .moderatelyActive
        self.fitnessGoals = [.maintenance]
        self.dietaryRestrictions = []
        self.allergies = []
        self.medicalConditions = []
        self.sleepGoal = 8
        self.waterGoal = 2.5
        self.dailyCalorieNeeds = 2000
        self.macroTargets = MacroTargets(protein: 30, carbs: 40, fats: 30)
        self.preferredWorkoutTypes = [.running, .weightTraining]
        self.workoutFrequency = .threeToFour
        self.measurementPreference = .metric
        self.notificationPreferences = NotificationPreferences(
            workoutReminders: true,
            mealReminders: true,
            waterReminders: true,
            sleepReminders: true,
            progressUpdates: true,
            reminderTimes: [:]
        )
        self.lastUpdateDate = Date()
        
        // Calculate actual calorie needs
        self.dailyCalorieNeeds = calculateCalorieTarget(for: .maintenance)
    }
}