import Foundation
import SwiftUI
import Combine
import HealthKit

final class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var nutritionData: NutritionData = NutritionData(waterIntake: 0.0)
    @Published var isAuthorized: Bool = false
    @Published var stepsToday: Int = 0
    @Published var activeCaloriesDay: Double = 0
    @Published var exerciseMinutes: Int = 0
    @Published var heartRate: Double = 0
    @Published var restingHeartRate: Double = 0
    @Published var vo2Max: Double = 0
    @Published var currentStreak: Int = 0
    @Published var workoutStats: WorkoutStats = WorkoutStats()
    @Published var recentWorkouts: [HKWorkout] = []
    
    struct NutritionData {
        var waterIntake: Double // in liters
    }
    
    struct BloodPressure {
        var systolic: Double
        var diastolic: Double
        var timestamp: Date
    }
    
    struct SleepAnalysis {
        var totalSleepHours: Double
        var deepSleepHours: Double
    }
    
    struct WorkoutStats {
        var thisWeekWorkouts: Int = 0
        var thisWeekCalories: Double = 0
        var thisWeekDuration: TimeInterval = 0
        var averageHeartRatePerWorkout: [UUID: Double] = [:]
        var totalDistanceThisWeek: Double = 0
        var personalBests: [WorkoutPersonalBest] = []
    }
    
    struct WorkoutPersonalBest {
        let type: HKWorkoutActivityType
        let value: Double
        let unit: String
        let date: Date
    }
    
    @Published var bloodPressure: BloodPressure = BloodPressure(systolic: 120, diastolic: 80, timestamp: Date())
    @Published var sleepAnalysis: SleepAnalysis = SleepAnalysis(totalSleepHours: 0, deepSleepHours: 0)
    
    init() {
        requestAuthorization()
        startMonitoring()
    }
    
    private func requestAuthorization() {
        // Define the types we want to read from HealthKit
        let typesToRead: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            HKQuantityType.quantityType(forIdentifier: .vo2Max)!,
            HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
        ]
        
        // Define the types we want to share (write) to HealthKit
        let typesToShare: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
            HKWorkoutType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if let error = error {
                    print("HealthKit authorization error: \(error.localizedDescription)")
                }
                if success {
                    self.refreshAllData()
                }
            }
        }
    }
    
    private func startMonitoring() {
        // Set up observers for real-time updates
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.refreshAllData()
        }
    }
    
    func refreshAllData() {
        fetchSteps()
        fetchActiveCalories()
        fetchExerciseMinutes()
        fetchHeartRate()
        fetchRestingHeartRate()
        fetchVO2Max()
        fetchBloodPressure()
        fetchSleepAnalysis()
        calculateStreak()
    }
    
    func addWaterIntake(amount: Double) {
        guard isAuthorized else { return }
        
        DispatchQueue.main.async {
            self.nutritionData.waterIntake += amount
            
            // Save to HealthKit
            if let waterType = HKObjectType.quantityType(forIdentifier: .dietaryWater) {
                let waterQuantity = HKQuantity(unit: .liter(), doubleValue: amount)
                let sample = HKQuantitySample(type: waterType,
                                            quantity: waterQuantity,
                                            start: Date(),
                                            end: Date())
                
                self.healthStore.save(sample) { (success, error) in
                    if let error = error {
                        print("Error saving water intake: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // Implementation of data fetching methods
    private func fetchSteps() {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { [weak self] _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                if let error = error {
                    print("Error fetching steps: \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.stepsToday = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActiveCalories() {
        guard let calorieType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: calorieType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { [weak self] _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                if let error = error {
                    print("Error fetching calories: \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.activeCaloriesDay = sum.doubleValue(for: HKUnit.kilocalorie())
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchExerciseMinutes() {
        guard let exerciseType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) else { return }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: exerciseType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { [weak self] _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                if let error = error {
                    print("Error fetching exercise minutes: \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.exerciseMinutes = Int(sum.doubleValue(for: HKUnit.minute()))
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHeartRate() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: heartRateType,
                                    quantitySamplePredicate: predicate,
                                    options: .discreteAverage) { [weak self] _, result, error in
            guard let result = result, let average = result.averageQuantity() else {
                if let error = error {
                    print("Error fetching heart rate: \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.heartRate = average.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchRestingHeartRate() {
        guard let restingHRType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: restingHRType,
                                    quantitySamplePredicate: predicate,
                                    options: .discreteAverage) { [weak self] _, result, error in
            guard let result = result, let average = result.averageQuantity() else {
                if let error = error {
                    print("Error fetching resting heart rate: \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.restingHeartRate = average.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchVO2Max() {
        guard let vo2Type = HKObjectType.quantityType(forIdentifier: .vo2Max) else { return }
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: vo2Type,
                                    quantitySamplePredicate: predicate,
                                    options: .discreteAverage) { [weak self] _, result, error in
            guard let result = result, let average = result.averageQuantity() else {
                if let error = error {
                    print("Error fetching VO2 max: \(error.localizedDescription)")
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.vo2Max = average.doubleValue(for: HKUnit.init(from: "mL/kg*min"))
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBloodPressure() {
        // For demo purposes, using mock data
        // In a real app, you would fetch this from HealthKit
        DispatchQueue.main.async {
            self.bloodPressure = BloodPressure(
                systolic: 120,
                diastolic: 80,
                timestamp: Date()
            )
        }
    }
    
    private func fetchSleepAnalysis() {
        // For demo purposes, using mock data
        // In a real app, you would fetch this from HealthKit
        DispatchQueue.main.async {
            self.sleepAnalysis = SleepAnalysis(
                totalSleepHours: 7.5,
                deepSleepHours: 2.5
            )
        }
    }
    
    private func calculateStreak() {
        // For demo purposes, using a mock value
        // In a real app, you would calculate this based on activity history
        DispatchQueue.main.async {
            self.currentStreak = 7
        }
    }
}