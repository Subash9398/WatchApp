import WatchKit
import Foundation
import HealthKit
import CoreMotion
import SwiftUI

// MARK: - Activity Type Definitions
enum ActivityType: Int, CaseIterable {
    case walking = 0
    case running = 1
    case sleeping = 2
    case stressMonitoring = 3
    case toothBrushing = 4
    case dishWashing = 5
    case volleyball = 6
    case football = 7
    case swimming = 8
    case cycling = 9
    case yoga = 10
    case meditation = 11
    
    var name: String {
        switch self {
        case .walking: return "Walking"
        case .running: return "Running"
        case .sleeping: return "Sleep"
        case .stressMonitoring: return "Stress"
        case .toothBrushing: return "Brushing"
        case .dishWashing: return "Dishes"
        case .volleyball: return "Volleyball"
        case .football: return "Football"
        case .swimming: return "Swimming"
        case .cycling: return "Cycling"
        case .yoga: return "Yoga"
        case .meditation: return "Meditation"
        }
    }
    
    var healthKitType: HKWorkoutActivityType {
        switch self {
        case .walking: return .walking
        case .running: return .running
        case .sleeping: return .mindAndBody
        case .stressMonitoring: return .mindAndBody
        case .toothBrushing: return .preparationAndRecovery
        case .dishWashing: return .preparationAndRecovery
        case .volleyball: return .volleyball
        case .football: return .americanFootball
        case .swimming: return .swimming
        case .cycling: return .cycling
        case .yoga: return .yoga
        case .meditation: return .mindAndBody
        }
    }
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .sleeping: return "bed.double"
        case .stressMonitoring: return "brain.head.profile"
        case .toothBrushing: return "mouth"
        case .dishWashing: return "drop.triangle"
        case .volleyball: return "circle.fill"
        case .football: return "sportscourt"
        case .swimming: return "figure.pool.swim"
        case .cycling: return "bicycle"
        case .yoga: return "figure.yoga"
        case .meditation: return "sparkles"
        }
    }
}

// MARK: - Metric Types
enum MetricType: String {
    case steps = "Steps"
    case distance = "Distance"
    case calories = "Calories"
    case heartRate = "Heart Rate"
    case heartRateVariability = "HRV"
    case duration = "Duration"
    case pace = "Pace"
    case sleepPhases = "Sleep Phases"
    case stressLevel = "Stress Level"
    case breathingRate = "Breathing Rate"
    case brushingZones = "Brushing Zones"
    case waterUsage = "Water Used"
    case intensity = "Intensity"
    case jumps = "Jumps"
    case strokeCount = "Strokes"
    case speed = "Speed"
    
    var unit: String {
        switch self {
        case .steps: return "steps"
        case .distance: return "km"
        case .calories: return "cal"
        case .heartRate: return "bpm"
        case .heartRateVariability: return "ms"
        case .duration: return "min"
        case .pace: return "min/km"
        case .sleepPhases: return "phases"
        case .stressLevel: return "score"
        case .breathingRate: return "br/min"
        case .brushingZones: return "zones"
        case .waterUsage: return "L"
        case .intensity: return "level"
        case .jumps: return "count"
        case .strokeCount: return "strokes"
        case .speed: return "km/h"
        }
    }
}

// MARK: - Activity Manager
class ActivityManager: ObservableObject {
    static let shared = ActivityManager()
    
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()
    private let pedometer = CMPedometer()
    
    @Published var currentActivity: ActivityType?
    @Published var isTracking = false
    @Published var metricValues: [MetricType: Double] = [:]
    
    private var startDate: Date?
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    private init() {
        setupMotionManager()
    }
    
    private func setupMotionManager() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
        }
    }
    
    func requestHealthPermissions(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]
        
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]
        
//        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: completion)
    }
    
    func startActivity(_ activity: ActivityType) {
        guard !isTracking else { return }
        
        currentActivity = activity
        startDate = Date()
        isTracking = true
        
        // Reset metrics
        metricValues.removeAll()
        
        switch activity {
        case .walking, .running:
            startPedometerUpdates()
            startWorkout(activityType: activity.healthKitType)
        case .sleeping:
            startSleepTracking()
        case .stressMonitoring:
            startStressMonitoring()
        case .toothBrushing:
            startBrushingTracking()
        case .dishWashing:
            startDishWashingTracking()
        case .volleyball, .football:
            startSportsTracking(activityType: activity.healthKitType)
        case .swimming:
            startSwimmingTracking()
        case .cycling:
            startCyclingTracking()
        case .yoga, .meditation:
            startMindBodyTracking(activityType: activity.healthKitType)
        }
    }
    
    func stopActivity(completion: @escaping (Bool, Error?) -> Void) {
        guard isTracking else {
            completion(false, nil)
            return
        }
        
        isTracking = false
        
        switch currentActivity {
        case .walking, .running, .volleyball, .football, .swimming, .cycling, .yoga, .meditation:
            stopWorkout(completion: completion)
        case .sleeping:
            stopSleepTracking(completion: completion)
        case .stressMonitoring:
            stopStressMonitoring(completion: completion)
        case .toothBrushing:
            stopBrushingTracking(completion: completion)
        case .dishWashing:
            stopDishWashingTracking(completion: completion)
        case .none:
            completion(false, nil)
        }
        
        pedometer.stopUpdates()
        motionManager.stopDeviceMotionUpdates()
    }
    
    // MARK: - Metrics Management
        func getMetricValue(_ metric: MetricType) -> Double {
            return metricValues[metric] ?? 0.0
        }
        
        func updateMetricValue(_ metric: MetricType, value: Double) {
            metricValues[metric] = value
        }
        
        private func resetMetrics() {
            metricValues.removeAll()
            
            // Initialize all metrics to zero
            guard let activity = currentActivity else { return }
//            for metric in activity.trackableMetrics {
//                metricValues[metric] = 0.0
//            }
        }
        
        // MARK: - Activity Specific Tracking
        private func startWorkout(activityType: HKWorkoutActivityType) {
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = activityType
            configuration.locationType = .outdoor
            
            do {
                workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
                workoutBuilder = workoutSession?.associatedWorkoutBuilder()
                
                workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                                    workoutConfiguration: configuration)
                
                workoutSession?.startActivity(with: Date())
                workoutBuilder?.beginCollection(withStart: Date()) { (success, error) in
                    if !success, let error = error {
                        print("Failed to begin workout: \(error.localizedDescription)")
                    }
                }
            } catch {
                print("Failed to start workout: \(error.localizedDescription)")
            }
        }
        
        private func stopWorkout(completion: @escaping (Bool, Error?) -> Void) {
            workoutSession?.end()
            workoutBuilder?.endCollection(withEnd: Date()) { [weak self] (success, error) in
                guard let self = self else { return }
                
                if success {
                    self.workoutBuilder?.finishWorkout { (workout, error) in
                        completion(workout != nil, error)
                    }
                } else {
                    completion(false, error)
                }
            }
        }
        
        private func startPedometerUpdates() {
            if CMPedometer.isStepCountingAvailable() {
                pedometer.startUpdates(from: Date()) { [weak self] (data, error) in
                    guard let self = self, let data = data else { return }
                    
                    // Update steps
                    self.updateMetricValue(.steps, value: Double(data.numberOfSteps.intValue))
                    
                    // Update distance if available
                    if let distance = data.distance?.doubleValue {
                        self.updateMetricValue(.distance, value: distance / 1000.0) // Convert to km
                        
                        // Calculate pace if we have time and distance
                        if let startDate = self.startDate, distance > 0 {
                            let elapsedTimeMinutes = Date().timeIntervalSince(startDate) / 60.0
                            let paceMinPerKm = elapsedTimeMinutes / (distance / 1000.0)
                            self.updateMetricValue(.pace, value: paceMinPerKm)
                        }
                    }
                    
                    // Notify observers that data has changed
                    NotificationCenter.default.post(name: NSNotification.Name("MetricsUpdated"), object: nil)
                }
            }
        }
        
        private func startSleepTracking() {
            // Start monitoring heart rate for sleep analysis
            // This would typically involve background heart rate monitoring
            // For now, we'll simulate sleep phases based on time
            
            startPeriodicUpdates(interval: 60.0) { [weak self] in
                guard let self = self, let startDate = self.startDate else { return }
                
                // Calculate sleep duration in minutes
                let elapsedMinutes = Date().timeIntervalSince(startDate) / 60.0
                self.updateMetricValue(.duration, value: elapsedMinutes)
                
                // Simulate sleep phases (would be determined by actual algorithms using HR, movement)
                let sleepPhases = min(floor(elapsedMinutes / 90.0), 5.0) // Approximately one phase per 90 minutes
                self.updateMetricValue(.sleepPhases, value: sleepPhases)
                
                // Simulate slower breathing rate during sleep
                self.updateMetricValue(.breathingRate, value: 12.0 + Double.random(in: -2.0...2.0))
                
                NotificationCenter.default.post(name: NSNotification.Name("MetricsUpdated"), object: nil)
            }
        }
        
        private func stopSleepTracking(completion: @escaping (Bool, Error?) -> Void) {
            // Would save the sleep data to HealthKit
            // For now, just simulate success
            completion(true, nil)
        }
        
        private func startStressMonitoring() {
            // Start heart rate and HRV monitoring
            // Would use algorithms to determine stress level based on HRV, HR, and other factors
            
            startPeriodicUpdates(interval: 10.0) { [weak self] in
                guard let self = self else { return }
                
                // Simulate heart rate (higher during stress)
                let simulatedHR = 65.0 + Double.random(in: 0...20.0)
                self.updateMetricValue(.heartRate, value: simulatedHR)
                
                // Simulate heart rate variability (lower during stress)
                let simulatedHRV = 65.0 - Double.random(in: 0...30.0)
                self.updateMetricValue(.heartRateVariability, value: max(simulatedHRV, 20.0))
                
                // Calculate stress level (simplified, would be more complex in reality)
                // Lower HRV and higher HR = higher stress
                let stressLevel = min(100.0, max(0.0, (85.0 - simulatedHRV) * 1.2))
                self.updateMetricValue(.stressLevel, value: stressLevel)
                
                // Breathing rate increases with stress
                let breathingRate = 12.0 + (stressLevel / 20.0)
                self.updateMetricValue(.breathingRate, value: breathingRate)
                
                NotificationCenter.default.post(name: NSNotification.Name("MetricsUpdated"), object: nil)
            }
        }
        
        private func stopStressMonitoring(completion: @escaping (Bool, Error?) -> Void) {
            // Would save the stress data
            completion(true, nil)
        }
        
        private func startBrushingTracking() {
            // Start motion detection for brushing
            if motionManager.isDeviceMotionAvailable {
                motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                    guard let self = self, let motion = motion else { return }
                    
                    // Track duration
                    if let startDate = self.startDate {
                        let elapsedSeconds = Date().timeIntervalSince(startDate)
                        self.updateMetricValue(.duration, value: elapsedSeconds / 60.0) // Convert to minutes
                    }
                    
                    // Detect brushing motion intensity using accelerometer data
                    let acceleration = motion.userAcceleration
                    let magnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
                    
                    // Update intensity based on motion
                    self.updateMetricValue(.intensity, value: magnitude * 10.0)
                    
                    // Simulate brushing zones (would be more complex in reality)
                    // Dental professionals recommend brushing all four quadrants of the mouth
                    let zonesCompleted = min(4.0, self.getMetricValue(.duration) * 4.0 / 2.0) // 2 minutes = all zones
                    self.updateMetricValue(.brushingZones, value: zonesCompleted)
                    
                    NotificationCenter.default.post(name: NSNotification.Name("MetricsUpdated"), object: nil)
                }
            }
        }
        
        private func stopBrushingTracking(completion: @escaping (Bool, Error?) -> Void) {
            // Would save the brushing data
            completion(true, nil)
        }
        
        private func startDishWashingTracking() {
            // Similar approach to brushing, but with different metrics
            if motionManager.isDeviceMotionAvailable {
                motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                    guard let self = self, let motion = motion else { return }
                    
                    // Track duration
                    if let startDate = self.startDate {
                        let elapsedSeconds = Date().timeIntervalSince(startDate)
                        self.updateMetricValue(.duration, value: elapsedSeconds / 60.0) // Convert to minutes
                    }
                    
                    // Detect washing motion intensity
                    let acceleration = motion.userAcceleration
                    let magnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
                    
                    // Update intensity based on motion
                    self.updateMetricValue(.intensity, value: magnitude * 10.0)
                    
                    // Simulate water usage based on duration
                    // Average is around 2-3L per minute of dishwashing
                    let waterUsage = self.getMetricValue(.duration) * 2.5
                    self.updateMetricValue(.waterUsage, value: waterUsage)
                    
                    NotificationCenter.default.post(name: NSNotification.Name("MetricsUpdated"), object: nil)
                }
            }
        }
        
        private func stopDishWashingTracking(completion: @escaping (Bool, Error?) -> Void) {
            // Would save the dish washing data
            completion(true, nil)
        }
        
        private func startSportsTracking(activityType: HKWorkoutActivityType) {
            // Start workout session for the sport
            startWorkout(activityType: activityType)
            
            // Track steps and motion for sports
            startPedometerUpdates()
            
            // For sports-specific metrics like jumps, we need motion analysis
            if motionManager.isDeviceMotionAvailable {
                motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                    guard let self = self, let motion = motion else { return }
                    
                    // Track intensity
                    let acceleration = motion.userAcceleration
                    let magnitude = sqrt(pow(acceleration.x, 2) + pow(acceleration.y, 2) + pow(acceleration.z, 2))
                    self.updateMetricValue(.intensity, value: magnitude * 10.0)
                    
                    // Detect jumps based on significant vertical acceleration
                    // This is simplified; real implementation would be more sophisticated
                    if acceleration.y > 1.5 { // Threshold for jump detection
                        let currentJumps = self.getMetricValue(.jumps)
                        self.updateMetricValue(.jumps, value: currentJumps + 1)
                    }
                    
                    // Track duration
                    if let startDate = self.startDate {
                        let elapsedMinutes = Date().timeIntervalSince(startDate) / 60.0
                        self.updateMetricValue(.duration, value: elapsedMinutes)
                    }
                    
                    NotificationCenter.default.post(name: NSNotification.Name("MetricsUpdated"), object: nil)
                }
            }
        }
        
        private func startSwimmingTracking() {
            // Start workout session for swimming
            startWorkout(activityType: .swimming)
            
            // Swimming specific tracking
            startPeriodicUpdates(interval: 5.0) { [weak self] in
                guard let self = self, let startDate = self.startDate else { return }
                
                // Track duration
                let elapsedMinutes = Date().timeIntervalSince(startDate) / 60.0
                self.updateMetricValue(.duration, value: elapsedMinutes)
                
                // Simulate swim distance (based on time)
                // Average swimming speed is around 2km/hour
                let distance = elapsedMinutes * (2.0 / 60.0) // km
                self.updateMetricValue(.distance, value: distance)
                
                // Calculate pace (min/km)
                if distance > 0 {
                    let pace = elapsedMinutes / distance
                    self.updateMetricValue(.pace, value: pace)
                }
                
                // Simulate stroke count (about 20 strokes per minute)
                let strokes = elapsedMinutes * 20.0
                self.updateMetricValue(.strokeCount, value: strokes)
                
                // Simulate calories burned (swimming burns about 500 calories per hour)
                let calories = elapsedMinutes * (500.0 / 60.0)
                self.updateMetricValue(.calories, value: calories)
                
                NotificationCenter.default.post(name: NSNotification.Name("MetricsUpdated"), object: nil)
            }
        }
    
    
        func readJSONFile(forName name: String) {
            do {
                if let bundlePath = Bundle.main.path(forResource: name, ofType: "json"),
                   let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
                    if let json = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: Any] {
                        print("JSON: \(json)")
                    } else {
                        print("Given JSON is not a valid dictionary object.")
                    }
                }
            } catch {
                print(error)
            }
        }
     
        
        private func startCyclingTracking() {
            // Start workout session for cycling
            
            readJSONFile(forName: "sample_configuration")
            
            startWorkout(activityType: .cycling)
            
            // Cycling specific tracking
            startPeriodicUpdates(interval: 5.0) { [weak self] in
                guard let self = self, let startDate = self.startDate else { return }
                
                // Track duration
                let elapsedMinutes = Date().timeIntervalSince(startDate) / 60.0
                self.updateMetricValue(.duration, value: elapsedMinutes)
                
                // Simulate cycling distance (based on time)
                // Average cycling speed is around 15km/hour
                let distance = elapsedMinutes * (15.0 / 60.0) // km
                self.updateMetricValue(.distance, value: distance)
                
                // Calculate speed (km/h)
                let speed = 15.0 + Double.random(in: -3.0...3.0) // Vary speed around 15km/h
                self.updateMetricValue(.speed, value: speed)
                
                // Calculate pace (min/km)
                if speed > 0 {
                    let pace = 60.0 / speed // min/km
                    self.updateMetricValue(.pace, value: pace)
                }
                
                // Simulate calories burned (cycling burns about 400 calories per hour)
                let calories = elapsedMinutes * (400.0 / 60.0)
                self.updateMetricValue(.calories, value: calories)
                
                // Simulate heart rate for cycling
                let heartRate = 120.0 + Double.random(in: -10.0...10.0)
                self.updateMetricValue(.heartRate, value: heartRate)
                
                NotificationCenter.default.post(name: NSNotification.Name("MetricsUpdated"), object: nil)
            }
        }
        
        private func startMindBodyTracking(activityType: HKWorkoutActivityType) {
            // Start workout session for yoga/meditation
            startWorkout(activityType: activityType)
            
            // Mind-body specific tracking
            startPeriodicUpdates(interval: 10.0) { [weak self] in
                guard let self = self, let startDate = self.startDate else { return }
                
                // Track duration
                let elapsedMinutes = Date().timeIntervalSince(startDate) / 60.0
                self.updateMetricValue(.duration, value: elapsedMinutes)
                
                // Simulate lower heart rate during yoga/meditation
                // Starting higher and gradually reducing
                let baseHeartRate = 75.0
                let reduction = min(20.0, elapsedMinutes * 2.0)
                let heartRate = baseHeartRate - reduction + Double.random(in: -3.0...3.0)
                self.updateMetricValue(.heartRate, value: max(55.0, heartRate))
                
                // Simulate slower breathing rate
                let breathingRate = 12.0 - min(6.0, elapsedMinutes / 10.0) + Double.random(in: -1.0...1.0)
                self.updateMetricValue(.breathingRate, value: max(4.0, breathingRate))
                
                // Simulate calories burned (yoga burns about 200-300 calories per hour)
                let calorieRate = (self.currentActivity == .yoga) ? 250.0 : 150.0 // Less for meditation
                let calories = elapsedMinutes * (calorieRate / 60.0)
                self.updateMetricValue(.calories, value: calories)
                
                NotificationCenter.default.post(name: NSNotification.Name("MetricsUpdated"), object: nil)
            }
        }
        
        // MARK: - Helper Methods
        private func startPeriodicUpdates(interval: TimeInterval, block: @escaping () -> Void) {
            // Create a timer that fires periodically
            let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                block()
            }
            // Store the timer somewhere if needed to invalidate it later
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    // MARK: - Main Interface Controller
    class MainInterfaceController: WKInterfaceController {
        
        // MARK: - Interface Outlets
        @IBOutlet weak var activityTableView: WKInterfaceTable!
        
        // MARK: - Properties
        private var activityList = ActivityType.allCases
        
        // MARK: - Lifecycle Methods
        override func awake(withContext context: Any?) {
            super.awake(withContext: context)
            
            setupTable()
            requestHealthPermissions()
        }
        
        // MARK: - Setup
        private func setupTable() {
            activityTableView.setNumberOfRows(activityList.count, withRowType: "ActivityRow")
            
            for (index, activity) in activityList.enumerated() {
                guard let row = activityTableView.rowController(at: index) as? ActivityRowController else { continue }
                row.configure(with: activity)
            }
        }
        
        private func requestHealthPermissions() {
            ActivityManager.shared.requestHealthPermissions { (success, error) in
                if !success {
                    self.presentAlert(withTitle: "Permission Required",
                                      message: "Health permissions are needed for tracking activities.",
                                      preferredStyle: .alert,
                                      actions: [WKAlertAction(title: "OK", style: .default, handler: {})])
                }
            }
        }
        
        // MARK: - Table Selection
        override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
            let selectedActivity = activityList[rowIndex]
            
            // Push to tracking interface with selected activity
            pushController(withName: "ActivityTrackingInterfaceController", context: selectedActivity)
        }
    }

    // MARK: - Activity Row Controller
    class ActivityRowController: NSObject {
        
        @IBOutlet weak var activityIcon: WKInterfaceImage!
        @IBOutlet weak var activityLabel: WKInterfaceLabel!
        
        func configure(with activity: ActivityType) {
            activityLabel.setText(activity.name)
            // activityIcon would be set with appropriate SF Symbol if available
            // For now, display generic icon
        }
    }

    // MARK: - Activity Tracking Interface Controller
    class ActivityTrackingInterfaceController: WKInterfaceController {
        
        // MARK: - Interface Outlets
        @IBOutlet weak var activityNameLabel: WKInterfaceLabel!
        @IBOutlet weak var startStopButton: WKInterfaceButton!
        @IBOutlet weak var metricsTable: WKInterfaceTable!
        
        // MARK: - Properties
        private var activity: ActivityType!
        private var isTracking = false
        
        // MARK: - Lifecycle Methods
        override func awake(withContext context: Any?) {
            super.awake(withContext: context)
            
            guard let activityType = context as? ActivityType else { return }
            activity = activityType
            
            setupInterface()
            setupObservers()
        }
        
        override func willActivate() {
            super.willActivate()
            updateMetricsDisplay()
        }
        
        override func didDeactivate() {
            super.didDeactivate()
            NotificationCenter.default.removeObserver(self)
        }
        
        // MARK: - Setup
        private func setupInterface() {
            activityNameLabel.setText(activity.name)
            startStopButton.setTitle("Start")
            
            setupMetricsTable()
        }
        
        private func setupMetricsTable() {
//            let metrics = activity.trackableMetrics
//            metricsTable.setNumberOfRows(metrics.count, withRowType: "MetricRow")
//            
//            for (index, metric) in metrics.enumerated() {
//                guard let row = metricsTable.rowController(at: index) as? MetricRowController else { continue }
//                row.configure(with: metric, value: 0.0)
//            }
        }
        
        private func setupObservers() {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(metricsUpdated),
                name: NSNotification.Name("MetricsUpdated"),
                object: nil
            )
        }
        
        // MARK: - Actions
        @IBAction func startStopButtonTapped() {
            if isTracking {
                stopActivity()
            } else {
                startActivity()
            }
        }
        
        private func startActivity() {
            isTracking = true
            startStopButton.setTitle("Stop")
            
            ActivityManager.shared.startActivity(activity)
        }
    
        private func stopActivity() {
                isTracking = false
                startStopButton.setTitle("Start")
                
                ActivityManager.shared.stopActivity { [weak self] (success, error) in
                    guard let self = self else { return }
                    
                    if !success {
                        if let error = error {
                            self.presentAlert(
                                withTitle: "Error",
                                message: "Failed to save activity: \(error.localizedDescription)",
                                preferredStyle: .alert,
                                actions: [WKAlertAction(title: "OK", style: .default, handler: {})]
                            )
                        }
                    } else {
                        // Show success message
                        self.presentAlert(
                            withTitle: "Activity Saved",
                            message: "Your \(self.activity.name) activity has been recorded successfully.",
                            preferredStyle: .alert,
                            actions: [WKAlertAction(title: "OK", style: .default, handler: {})]
                        )
                    }
                }
            }
        
        @objc private func metricsUpdated() {
               DispatchQueue.main.async {
                   self.updateMetricsDisplay()
               }
           }
           
           private func updateMetricsDisplay() {
//               let metrics = activity.trackableMetrics
//               
//               for (index, metric) in metrics.enumerated() {
//                   guard let row = metricsTable.rowController(at: index) as? MetricRowController else { continue }
//                   let value = ActivityManager.shared.getMetricValue(metric)
//                   row.update(value: value)
//               }
           }
        
}


//#Preview {
//    ActivityListView()
//}

