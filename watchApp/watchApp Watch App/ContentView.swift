//
//  ContentView.swift
//  watchApp Watch App
//
//  Created by Madhu Office on 16/04/2025.
//

// MARK: - WatchOS Sensor Access Examples
// This sample demonstrates how to access various sensors on Apple Watch
// Includes examples for: CoreMotion, HealthKit, and CoreLocation

import SwiftUI
import CoreMotion
import HealthKit
import CoreLocation

class SensorManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Published properties to observe in SwiftUI
    @Published var heartRate: Double = 0
    @Published var steps: Int = 0
    @Published var acceleration: CMAcceleration = CMAcceleration(x: 0, y: 0, z: 0)
    @Published var rotationRate: CMRotationRate = CMRotationRate(x: 0, y: 0, z: 0)
    @Published var location: CLLocation?
    @Published var bloodOxygen: Double = 0
   
    // Managers
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()
    private let pedometer = CMPedometer()
    private let locationManager = CLLocationManager()
   
    override init() {
        super.init()
        setupLocationManager()
    }
   
    func setupHealthKit() {
        // Types we want to read
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
//            HKObjectType.quantityType(forIdentifier: .bloodOxygen)!
        ]
       
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.startHeartRateQuery()
//                self.startBloodOxygenQuery()
                self.startPedometerUpdates()
            } else if let error = error {
                print("HealthKit authorization failed: \(error.localizedDescription)")
            }
        }
    }
   
    // MARK: - HealthKit Methods
   
    private func startHeartRateQuery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
       
        // Create query to continuously monitor heart rate
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, error in
               
                guard let samples = samples as? [HKQuantitySample], let sample = samples.last else { return }
                DispatchQueue.main.async {
                    self?.heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                }
            }
       
        // Updates handler
        query.updateHandler = { [weak self] query, samples, _, _, error in
            guard let samples = samples as? [HKQuantitySample], let sample = samples.last else { return }
            DispatchQueue.main.async {
                self?.heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
        }
       
        healthStore.execute(query)
    }
   
//    private func startBloodOxygenQuery() {
//        guard let bloodOxygenType = HKObjectType.quantityType(forIdentifier: .bloodOxygen) else { return }
//       
//        let query = HKAnchoredObjectQuery(
//            type: bloodOxygenType,
//            predicate: nil,
//            anchor: nil,
//            limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, error in
//               
//                guard let samples = samples as? [HKQuantitySample], let sample = samples.last else { return }
//                DispatchQueue.main.async {
//                    self?.bloodOxygen = sample.quantity.doubleValue(for: HKUnit.percent())
//                }
//            }
//       
//        query.updateHandler = { [weak self] query, samples, _, _, error in
//            guard let samples = samples as? [HKQuantitySample], let sample = samples.last else { return }
//            DispatchQueue.main.async {
//                self?.bloodOxygen = sample.quantity.doubleValue(for: HKUnit.percent())
//            }
//        }
//       
//        healthStore.execute(query)
//    }
   
    private func startPedometerUpdates() {
        if CMPedometer.isStepCountingAvailable() {
            let now = Date()
            pedometer.startUpdates(from: now) { [weak self] data, error in
                if let data = data {
                    DispatchQueue.main.async {
                        self?.steps = data.numberOfSteps.intValue
                    }
                }
            }
        }
    }
   
    // MARK: - CoreMotion Methods
   
    func startMotionUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.5
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
                if let data = data {
                    self?.acceleration = data.acceleration
                }
            }
        }
       
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.5
            motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
                if let data = data {
                    self?.rotationRate = data.rotationRate
                }
            }
        }
    }
   
    // MARK: - CoreLocation Methods
   
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
   
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
   
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.location = location
        }
    }
   
    func stopAllSensors() {
        // Stop HealthKit queries
//        healthStore.stop(HKQuery())
       
        // Stop CoreMotion updates
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        pedometer.stopUpdates()
       
        // Stop CoreLocation updates
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - SwiftUI View to Display Sensor Data

struct ContentView: View {
    @StateObject private var sensorManager = SensorManager()
   
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Health Data")) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Heart Rate")
                        Spacer()
                        Text("\(Int(sensorManager.heartRate)) BPM")
                    }
                   
                    HStack {
                        Image(systemName: "lungs.fill")
                            .foregroundColor(.blue)
                        Text("Blood Oxygen")
                        Spacer()
                        Text("\(Int(sensorManager.bloodOxygen * 100))%")
                    }
                   
                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.green)
                        Text("Steps")
                        Spacer()
                        Text("\(sensorManager.steps)")
                    }
                }
               
                Section(header: Text("Motion Data")) {
                    VStack(alignment: .leading) {
                        Text("Acceleration")
                        Text("X: \(String(format: "%.2f", sensorManager.acceleration.x))")
                        Text("Y: \(String(format: "%.2f", sensorManager.acceleration.y))")
                        Text("Z: \(String(format: "%.2f", sensorManager.acceleration.z))")
                    }
                   
                    VStack(alignment: .leading) {
                        Text("Rotation Rate")
                        Text("X: \(String(format: "%.2f", sensorManager.rotationRate.x))")
                        Text("Y: \(String(format: "%.2f", sensorManager.rotationRate.y))")
                        Text("Z: \(String(format: "%.2f", sensorManager.rotationRate.z))")
                    }
                }
               
                Section(header: Text("Location Data")) {
                    if let location = sensorManager.location {
                        VStack(alignment: .leading) {
                            Text("Latitude: \(String(format: "%.4f", location.coordinate.latitude))")
                            Text("Longitude: \(String(format: "%.4f", location.coordinate.longitude))")
                            Text("Altitude: \(String(format: "%.1f", location.altitude)) m")
                            Text("Speed: \(String(format: "%.1f", location.speed)) m/s")
                        }
                    } else {
                        Text("Location data not available")
                    }
                }
            }
            .navigationTitle("Watch Sensors")
            .onAppear {
//                sensorManager.setupHealthKit()
                sensorManager.startMotionUpdates()
                sensorManager.startLocationUpdates()
            }
            .onDisappear {
                sensorManager.stopAllSensors()
            }
        }
    }
}


#Preview {
    ActivityListView()
}



