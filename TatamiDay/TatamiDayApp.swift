import SwiftUI
import UserNotifications

@main
struct TatamiDayApp: App {
    @State private var store: AppStore

    init() {
        let store = AppStore()
        _store = State(initialValue: store)
        NotificationBridge.shared.store = store
        UNUserNotificationCenter.current().delegate = NotificationBridge.shared
        NotificationScheduler.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
