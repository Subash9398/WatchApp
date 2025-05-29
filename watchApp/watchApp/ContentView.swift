import SwiftUI
import WatchConnectivity
import Supabase
import Foundation

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    
    private let session = WCSession.default
    
    override init() {
        super.init()
        if WCSession.isSupported() {
//            session.delegate = self
//            session.activate()
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("Session activation failed with error: \(error.localizedDescription)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        session.activate()
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    // iOS-specific required method
    #if os(iOS)
    func sessionWatchStateDidChange(_ session: WCSession) {
        // Handle state change if needed
    }
    #endif
}

struct ContentView: View {
    @StateObject private var watchSession = WatchSessionManager.shared
    
    var body: some View {
        BookmarkRow()
    }
}

struct BookmarkRow: View {
    @State private var calories = ""
    @State private var distance = ""
    @State private var heartRate = ""
    @State private var breathing = ""
    @State private var duration = ""
    @State var walk: [Walking] = []
    
    @State private var email = ""
    @State private var password = ""
    
    @State private var isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    
    @State private var userId = ""
    
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Login")
                .font(.title).multilineTextAlignment(.center)
            if #available(iOS 17.0, *) {
                TextField("Enter email address", text: $email).frame(height: 50)
                    .multilineTextAlignment(.leading).border(.fill)
            } else {
                TextField("Enter Email address", text: $email).frame(height: 50)
                    .multilineTextAlignment(.leading).overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            if #available(iOS 17.0, *) {
                TextField("Enter the password", text: $password).frame(height: 50)
                    .multilineTextAlignment(.leading).border(.fill)
            } else {
                TextField("Enter the password", text: $password).frame(height: 50)
                    .multilineTextAlignment(.leading).overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            
            Button(action: {
                print("Login")
//                Task {
//                    await login()
//                }
                readJSONFile(forName: "sample_configuration")
            }) {
                if #available(iOS 15.0, *) {
                    Text("Login")
                        .padding()
                        .foregroundColor(.white)
                        .background(.orange)
                        .cornerRadius(10).frame(alignment: .center)
                } else {
                    Text("Login")
                        .padding()
                        .foregroundColor(.orange)
                        .cornerRadius(10).frame(alignment: .center)
                }
            }.frame(alignment: .center)
        }.padding(.top).padding(.leading).padding(.trailing).hidden(self.isLoggedIn)
        VStack(alignment: .leading) {
                Text("Update Fields")
                    .font(.title).multilineTextAlignment(.center)
                if #available(iOS 17.0, *) {
                    TextField("Enter the calories", text: $calories).frame(height: 50)
                        .multilineTextAlignment(.leading).border(.fill)
                } else {
                    TextField("Enter the calories", text: $calories).frame(height: 50)
                        .multilineTextAlignment(.leading).overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                if #available(iOS 17.0, *) {
                    TextField("Enter the distance", text: $distance).frame(height: 50)
                        .multilineTextAlignment(.leading).border(.fill)
                } else {
                    TextField("Enter the distance", text: $distance).frame(height: 50)
                        .multilineTextAlignment(.leading).overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                if #available(iOS 17.0, *) {
                    TextField("Enter the heartRate", text: $heartRate).frame(height: 50)
                        .multilineTextAlignment(.leading).border(.fill)
                } else {
                    TextField("Enter the heartRate", text: $heartRate).frame(height: 50)
                        .multilineTextAlignment(.leading).overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                if #available(iOS 17.0, *) {
                    TextField("Enter the breathing", text: $breathing).frame(height: 50)
                        .multilineTextAlignment(.leading).border(.fill)
                } else {
                    TextField("Enter the breathing", text: $breathing).frame(height: 50)
                        .multilineTextAlignment(.leading).overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                if #available(iOS 17.0, *) {
                    TextField("Enter the duration", text: $duration).frame(height: 50)
                        .multilineTextAlignment(.leading).border(.fill).frame(height: 50)
                } else {
                    TextField("Enter the duration", text: $duration).frame(height: 50)
                        .multilineTextAlignment(.leading).frame(height: 50).overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
                Button(action: {
                    print("Button Tapped")
                    Task {
                        await check()
                    }
                }) {
                    if #available(iOS 15.0, *) {
                        Text("Update")
                            .padding()
                            .foregroundColor(.white)
                            .background(.orange)
                            .cornerRadius(10)
                    } else {
                        Text("Update")
                            .padding()
                            .foregroundColor(.orange)
                            .cornerRadius(10)
                    }
                }.frame(alignment: .center)
            
            Button(action: {
                print("Button Tapped")
                Task {
                    await getDataFromDatabase()
                }
            }) {
                if #available(iOS 15.0, *) {
                    Text("Get")
                        .padding()
                        .foregroundColor(.white)
                        .background(.orange)
                        .cornerRadius(10)
                } else {
                    Text("Get")
                        .padding()
                        .foregroundColor(.orange)
                        .cornerRadius(10)
                }
            }.frame(alignment: .center)
            
            Button(action: {
                print("Button Tapped")
                Task {
                    logOut()
                }
            }) {
                if #available(iOS 15.0, *) {
                    Text("Logout")
                        .padding()
                        .foregroundColor(.white)
                        .background(.orange)
                        .cornerRadius(10)
                } else {
                    Text("LogOut")
                        .padding()
                        .foregroundColor(.orange)
                        .cornerRadius(10)
                }
            }.frame(alignment: .center)
            
        }.padding(.top).padding(.leading).padding(.trailing).hidden(!self.isLoggedIn)
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
    
    func check() async  {
        if (self.calories != "" && self.breathing != "" && self.duration != "" && self.distance != "" && self.heartRate != "") {
            await insertToDatabase()
        } else {
            debugPrint("Please enter all values to insert")
        }
    }
    
    func login() async  {
        if (self.email != "" && self.password != "") {
            let supabase = SupabaseClient(
              supabaseURL: URL(string: "https://ghvbzgiwxrlshaznzniw.supabase.co")!,
              supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdodmJ6Z2l3eHJsc2hhem56bml3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUyMTk3MjksImV4cCI6MjA2MDc5NTcyOX0.juTrxYkdkNBvb_qIZ-HAa7y38ZCZrI8xRtJQkcNO2zc"
            )
            do {
                let data = try await supabase.auth.signIn(
                email: self.email,
                password: self.password
              )
                debugPrint(data.user.id)
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                self.userId = data.user.id.uuidString
                self.isLoggedIn = true
            } catch {
                debugPrint(error)
                dump(error)
            }
        } else {
            debugPrint("Please enter all values to insert")
        }
    }
    
    
    
    func insertToDatabase() async {
        let supabase = SupabaseClient(
          supabaseURL: URL(string: "https://ghvbzgiwxrlshaznzniw.supabase.co")!,
          supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdodmJ6Z2l3eHJsc2hhem56bml3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUyMTk3MjksImV4cCI6MjA2MDc5NTcyOX0.juTrxYkdkNBvb_qIZ-HAa7y38ZCZrI8xRtJQkcNO2zc"
        )
        
        var wal = WalkingUpload(created_at: Date(), calories: self.calories, distance: self.distance, heartRate: self.heartRate, breathing: self.breathing, duration: self.duration, userId: self.userId)
//        var wal = WalkingUpload(created_at: Date(), calories: "100", distance: "2.1", heartRate: "100", breathing: "102", duration: "60", uuid: UUID().uuidString)
        
        do {
            debugPrint(Date())
            try await supabase.from("walking").insert(wal)
                .execute()
            debugPrint(wal)
//            self.walk = try await supabase.from("walking").select().execute().value
//            print("Fetched data: \(self.walk)")
            // Rest of your code...
        } catch {
            dump(error)
        }
    }
    
    func getDataFromDatabase() async {
        let supabase = SupabaseClient(
          supabaseURL: URL(string: "https://ghvbzgiwxrlshaznzniw.supabase.co")!,
          supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdodmJ6Z2l3eHJsc2hhem56bml3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUyMTk3MjksImV4cCI6MjA2MDc5NTcyOX0.juTrxYkdkNBvb_qIZ-HAa7y38ZCZrI8xRtJQkcNO2zc"
        )
        
        do {
            
            self.walk = try await supabase.from("walking").select().execute().value
            print("Fetched data: \(self.walk)")
            // Rest of your code...
        } catch {
            dump(error)
        }
    }
    
    func logOut() {
        self.isLoggedIn = false
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
    }
}

// Assuming this is your Bookmark model
struct Walking: Codable {
    var id: Int
    var created_at: Date
    var calories: String
    var distance: String
    var heartRate: String
    var breathing: String
    var duration: String
    var userId: String
}

struct WalkingUpload: Codable {
    var created_at: Date
    var calories: String
    var distance: String
    var heartRate: String
    var breathing: String
    var duration: String
    var userId: String
}

extension View {
    /// Custom extension to allow `.hidden(_:)` with a Bool
    @ViewBuilder func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }
}

//#Preview {
//    ContentView()
//}

