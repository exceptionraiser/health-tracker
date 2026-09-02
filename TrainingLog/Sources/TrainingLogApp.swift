import SwiftUI

@main
struct TrainingLogApp: App {
    @StateObject private var store = Store()
    @StateObject private var reminders = ReminderManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(reminders)
                .preferredColorScheme(.light)
        }
    }
}
