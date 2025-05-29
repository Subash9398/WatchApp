import SwiftUI
import HealthKit

struct ActivityListView: View {
    let activities = ActivityType.allCases
    
    var body: some View {
        List(activities, id: \.self) { activity in
            NavigationLink(destination: ActivityTrackingView(activity: activity)) {
                ActivityRowView(activity: activity)
            }
        }
        .navigationTitle("Activities")
        .onAppear {
            ActivityManager.shared.requestHealthPermissions { success, error in
                if !success {
                    print("Failed to get health permissions: \(String(describing: error))")
                }
            }
        }
    }
}

struct ActivityRowView: View {
    let activity: ActivityType
    
    var body: some View {
        HStack {
            Image(systemName: activity.icon)
                .font(.title2)
            Text(activity.name)
                .font(.body)
        }
        .padding(.vertical, 4)
    }
}

struct ActivityTrackingView: View {
    let activity: ActivityType
    @StateObject private var activityManager = ActivityManager.shared
    
    var body: some View {
        VStack {
            Text(activity.name)
                .font(.title2)
                .padding(.top)
            
            if activityManager.isTracking {
                MetricsGridView(activity: activity)
                    .padding().frame(height: 120)
            }
            
            Spacer()
            
            Button(action: {
                if activityManager.isTracking {
                    activityManager.stopActivity { success, error in
                        if !success {
                            print("Failed to stop activity: \(String(describing: error))")
                        }
                    }
                } else {
                    activityManager.startActivity(activity)
                }
            }) {
                Text(activityManager.isTracking ? "Stop" : "Start")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(activityManager.isTracking ? Color.red : Color.green)
                    .cornerRadius(10)
            }
            .padding(.bottom)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MetricsGridView: View {
    let activity: ActivityType
    @StateObject private var activityManager = ActivityManager.shared
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(Array(activityManager.metricValues.keys), id: \.self) { metric in
                    MetricView(metric: metric, value: activityManager.metricValues[metric] ?? 0)
                }
            }
        }
    }
}

struct MetricView: View {
    let metric: MetricType
    let value: Double
    
    var formattedValue: String {
        switch metric {
        case .pace, .duration:
            let minutes = Int(value)
            let seconds = Int((value - Double(minutes)) * 60)
            return String(format: "%d:%02d %@", minutes, seconds, metric.unit)
        case .steps, .jumps, .strokeCount:
            return String(format: "%.0f %@", value, metric.unit)
        case .brushingZones, .sleepPhases:
            let maxValue: Double = (metric == .brushingZones) ? 4.0 : 5.0
            return String(format: "%.0f/%0.f %@", min(value, maxValue), maxValue, metric.unit)
        case .stressLevel:
            return String(format: "%.0f/100 %@", value, metric.unit)
        default:
            return String(format: "%.1f %@", value, metric.unit)
        }
    }
    
    var body: some View {
        VStack {
            Text(metric.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(formattedValue)
                .font(.body)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.secondary.opacity(0.2))
        .cornerRadius(8)
    }
}

//#Preview {
//    ActivityListView()
//}
