import Foundation
import UserNotifications

@MainActor
enum NotificationScheduler {
    static func registerCategories() {
        let done = UNNotificationAction(identifier: "tatami.done", title: "Mark Done", options: [])
        let snooze = UNNotificationAction(identifier: "tatami.snooze", title: "Remind in 30 minutes", options: [])
        let due = UNNotificationCategory(identifier: "tatami.due", actions: [done, snooze], intentIdentifiers: [], options: [])
        let lead = UNNotificationCategory(identifier: "tatami.lead", actions: [], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([due, lead])
    }

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    static func resync(_ store: AppStore) async {
        let sessions = store.sessions
        let names = topicNames(in: store)
        await deliver(sessions: sessions, topicNames: names)
    }

    static func removeAll() async {
        let center = UNUserNotificationCenter.current()
        await removeOurs(from: center)
        try? await center.setBadgeCount(0)
    }

    private static func deliver(sessions: [Session], topicNames: [UUID: String]) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let allowed: Set<UNAuthorizationStatus> = [.authorized, .provisional, .ephemeral]
        await removeOurs(from: center)
        guard allowed.contains(settings.authorizationStatus) else {
            try? await center.setBadgeCount(0)
            return
        }

        let now = Date()
        let horizon = now.addingTimeInterval(72 * 60 * 60)
        var notes: [Planned] = []
        for session in sessions where !session.isComplete {
            let topic = topicNames[session.topicID] ?? "Training"
            if let lead = session.leadMinutes {
                let fire = session.start.addingTimeInterval(TimeInterval(-lead * 60))
                if fire > now && fire < horizon {
                    notes.append(
                        planned(
                            id: "tatami.lead.\(session.id.uuidString)",
                            title: session.title,
                            body: "\(topic) starts in \(lead) min.",
                            fire: fire,
                            sessionID: session.id,
                            category: "tatami.lead",
                            kind: "lead"
                        )
                    )
                }
            }
            if session.requiresCompletion && session.end > now && session.end < horizon {
                notes.append(
                    planned(
                        id: "tatami.due.\(session.id.uuidString)",
                        title: "Mark done",
                        body: "\(session.title) is finished. It stays open until you mark it done.",
                        fire: session.end,
                        sessionID: session.id,
                        category: "tatami.due",
                        kind: "due"
                    )
                )
            }
            if let snooze = session.snoozedUntil, snooze > now, snooze < horizon {
                notes.append(
                    planned(
                        id: "tatami.snooze.\(session.id.uuidString)",
                        title: "Mark done",
                        body: "\(session.title) is still open.",
                        fire: snooze,
                        sessionID: session.id,
                        category: "tatami.due",
                        kind: "snooze"
                    )
                )
            }
        }

        let overdue = sessions.filter { $0.needsMark(at: now) }.sorted { $0.end < $1.end }
        var summaries: [Planned] = []
        if !overdue.isEmpty {
            let names = overdue.prefix(3).map(\.title).joined(separator: ", ")
            let extra = overdue.count > 3 ? " +\(overdue.count - 3) more" : ""
            let body = "\(overdue.count) still open: \(names)\(extra). Mark them done."
            for offset in 0..<3 {
                guard let morning = date(hour: 8, minute: 0, dayOffset: offset), morning > now else { continue }
                summaries.append(
                    planned(
                        id: "tatami.summary.\(Int(morning.timeIntervalSince1970))",
                        title: "Close the day",
                        body: body,
                        fire: morning,
                        sessionID: nil,
                        category: "",
                        kind: "summary"
                    )
                )
            }
        }

        var chosen = notes.sorted { $0.fire < $1.fire }
        if chosen.count > 57 {
            chosen = Array(chosen.prefix(57))
        }
        chosen.append(contentsOf: summaries.prefix(3))
        for note in chosen {
            try? await center.add(note.request)
        }
        try? await center.setBadgeCount(min(overdue.count, 99))
    }

    private static func topicNames(in store: AppStore) -> [UUID: String] {
        var names: [UUID: String] = [:]
        for topic in store.topics {
            names[topic.id] = topic.name
        }
        return names
    }

    private static func planned(
        id: String,
        title: String,
        body: String,
        fire: Date,
        sessionID: UUID?,
        category: String,
        kind: String
    ) -> Planned {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if !category.isEmpty {
            content.categoryIdentifier = category
        }
        content.threadIdentifier = "tatami"
        var info: [String: Any] = ["kind": kind]
        if let sessionID {
            info["sessionID"] = sessionID.uuidString
        }
        content.userInfo = info
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        return Planned(fire: fire, request: request)
    }

    private static func date(hour: Int, minute: Int, dayOffset: Int) -> Date? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { return nil }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }

    private static func removeOurs(from center: UNUserNotificationCenter) async {
        let pending = await center.pendingNotificationRequests()
        let pendingIDs = pending.map(\.identifier).filter { $0.hasPrefix("tatami.") }
        if !pendingIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: pendingIDs)
        }
        let delivered = await center.deliveredNotifications()
        let deliveredIDs = delivered.map(\.request.identifier).filter { $0.hasPrefix("tatami.") }
        if !deliveredIDs.isEmpty {
            center.removeDeliveredNotifications(withIdentifiers: deliveredIDs)
        }
    }

    private struct Planned {
        var fire: Date
        var request: UNNotificationRequest
    }
}

final class NotificationBridge: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationBridge()
    nonisolated(unsafe) weak var store: AppStore?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        let sessionID = info["sessionID"] as? String
        let kind = info["kind"] as? String
        let action = response.actionIdentifier
        Task { @MainActor in
            self.store?.handleNotification(action: action, sessionID: sessionID, kind: kind)
            completionHandler()
        }
    }
}
