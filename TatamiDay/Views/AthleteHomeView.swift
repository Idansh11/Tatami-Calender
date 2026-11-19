import SwiftUI
import UIKit
import UserNotifications

struct AthleteHomeView: View {
    @Environment(AppStore.self) private var store
    @State private var authorization: UNAuthorizationStatus = .notDetermined
    @State private var exportDocument = BackupDocument(data: Data())
    @State private var exporting = false
    @State private var importing = false
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    var body: some View {
        let days = store.daysInSelectedWeek()
        let peak = max(days.map { store.completedMinutes(on: $0) }.max() ?? 0, 45)
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(store.athleteName)
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.ink)
                            Text(store.profileEmail.isEmpty ? "Signed in" : store.profileEmail)
                                .font(.footnote)
                                .foregroundStyle(Theme.secondary)
                            HStack(spacing: 16) {
                                stat(title: "Streak", value: "\(store.currentStreak())d")
                                stat(title: "This week", value: TimeText.minutes(weekMinutes(days)))
                                stat(title: "Open", value: "\(store.overdueCount)")
                            }
                            .padding(.top, 8)
                        }
                        .listRowBackground(Theme.surface)

                        weekChart(days: days, peak: peak)
                            .listRowBackground(Theme.surface)

                        if store.topicMinutesThisWeek().isEmpty {
                            Text("Marked sessions show up here as load by topic.")
                                .font(.footnote)
                                .foregroundStyle(Theme.secondary)
                                .listRowBackground(Theme.surface)
                        } else {
                            ForEach(store.topicMinutesThisWeek()) { item in
                                HStack(spacing: 10) {
                                    Circle().fill(Color(hex: item.topic.colorHex)).frame(width: 10, height: 10)
                                    Text(item.topic.name)
                                        .foregroundStyle(Theme.ink)
                                    Spacer()
                                    Text(TimeText.minutes(item.minutes))
                                        .foregroundStyle(Theme.secondary)
                                        .font(.subheadline.monospacedDigit())
                                }
                                .listRowBackground(Theme.surface)
                            }
                        }
                    } header: {
                        Text("This week")
                    }

                    Section("Still open") {
                        if store.overdueSessions().isEmpty && store.upcomingSessions().isEmpty {
                            Text("Nothing waiting. Add a session from the calendar.")
                                .foregroundStyle(Theme.secondary)
                                .listRowBackground(Theme.surface)
                        }
                        ForEach(store.overdueSessions().prefix(6)) { session in
                            sessionRow(session, open: true)
                        }
                        ForEach(store.upcomingSessions()) { session in
                            sessionRow(session, open: false)
                        }
                        if store.overdueCount > 0 {
                            Button("Review marks") { store.showOverdueSheet = true }
                                .listRowBackground(Theme.surface)
                        }
                    }

                    Section("Plan") {
                        Button("Add a training week") { store.addTrainingPlan() }
                            .listRowBackground(Theme.surface)
                        NavigationLink("History") { HistoryView() }
                            .listRowBackground(Theme.surface)
                    }

                    Section("Alerts") {
                        alertRow
                    }

                    Section("Appearance") {
                        Picker("Appearance", selection: appearanceBinding) {
                            ForEach(AppearanceChoice.allCases) { choice in
                                Text(choice.title).tag(choice)
                            }
                        }
                        .listRowBackground(Theme.surface)
                    }

                    Section("Backup") {
                        Button("Export backup") {
                            exportDocument = BackupDocument(data: store.exportData() ?? Data())
                            exporting = true
                        }
                        .listRowBackground(Theme.surface)
                        Button("Import backup") { importing = true }
                            .listRowBackground(Theme.surface)
                    }

                    Section {
                        NavigationLink("Privacy policy") { PrivacyPolicyView() }
                            .listRowBackground(Theme.surface)
                        Button("Sign out") { confirmSignOut = true }
                            .listRowBackground(Theme.surface)
                        Button("Delete account", role: .destructive) { confirmDelete = true }
                            .listRowBackground(Theme.surface)
                    } header: {
                        Text("Account")
                    } footer: {
                        Text("Tatami Day is a planner for your own training. It is not a medical device and it does not tell you how to train or how to treat an injury.\n\n\(versionText)")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Athlete")
            .task { await refreshAuthorization() }
            .fileExporter(
                isPresented: $exporting,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "Tatami-Day-Backup"
            ) { result in
                if case .failure = result {
                    store.alertMessage = "The backup was not saved."
                }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                guard case .success(let urls) = result, let url = urls.first else { return }
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                guard let data = try? Data(contentsOf: url) else {
                    store.alertMessage = "That file could not be read."
                    return
                }
                store.importData(data)
            }
            .confirmationDialog("Sign out?", isPresented: $confirmSignOut, titleVisibility: .visible) {
                Button("Sign out", role: .destructive) { store.signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This calendar stays on this iPhone for this account. Another sign-in opens a different calendar.")
            }
            .confirmationDialog("Delete this account?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete account and sessions", role: .destructive) { store.deleteAccount() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes Sign in with Apple from Tatami Day on this iPhone and deletes every session. There is no server copy.")
            }
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func weekChart(days: [Date], peak: Int) -> some View {
        let calendar = Calendar.current
        return HStack(alignment: .bottom, spacing: 8) {
            ForEach(days, id: \.self) { day in
                let minutes = store.completedMinutes(on: day)
                let height = max(4, 110 * CGFloat(minutes) / CGFloat(peak))
                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(calendar.isDateInToday(day) ? Theme.gold : Theme.tatami)
                        .frame(height: height)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.secondary)
                }
                .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide))), \(TimeText.minutes(minutes)) done")
            }
        }
        .frame(height: 150)
        .padding(.vertical, 6)
    }

    private func sessionRow(_ session: Session, open: Bool) -> some View {
        Button {
            store.inspectedSessionID = session.id
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(store.color(for: session))
                    .frame(width: 4, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title)
                        .foregroundStyle(Theme.ink)
                    Text(TimeText.range(start: session.start, end: session.end))
                        .font(.caption)
                        .foregroundStyle(Theme.secondary)
                }
                Spacer()
                if open {
                    Text("Mark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.ember)
                }
            }
        }
        .listRowBackground(Theme.surface)
    }

    @ViewBuilder
    private var alertRow: some View {
        switch authorization {
        case .authorized, .provisional, .ephemeral:
            VStack(alignment: .leading, spacing: 8) {
                Text("Alerts are on. Tatami Day reminds you before a session and again when it needs to be marked done.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondary)
                Button("Refresh reminders") {
                    Task { await NotificationScheduler.resync(store) }
                }
            }
            .listRowBackground(Theme.surface)
        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Text("Alerts are off. Turn them on in Settings to hear about sessions.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondary)
                Button("Open Settings") { openNotificationSettings() }
            }
            .listRowBackground(Theme.surface)
        default:
            Button("Turn on alerts") {
                Task {
                    _ = await NotificationScheduler.requestAuthorization()
                    await refreshAuthorization()
                    await NotificationScheduler.resync(store)
                }
            }
            .listRowBackground(Theme.surface)
        }
    }

    private var appearanceBinding: Binding<AppearanceChoice> {
        Binding(
            get: { store.settings.appearance },
            set: { choice in
                store.updateSettings { $0.appearance = choice }
            }
        )
    }

    private func weekMinutes(_ days: [Date]) -> Int {
        days.reduce(0) { $0 + store.completedMinutes(on: $1) }
    }

    private func refreshAuthorization() async {
        authorization = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Tatami Day \(version) (\(build))"
    }
}

struct HistoryView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            Group {
                if store.historyGroups().isEmpty {
                    ContentUnavailableView(
                        "No history yet",
                        systemImage: "clock",
                        description: Text("Finished and past sessions collect here.")
                    )
                } else {
                    List {
                        ForEach(store.historyGroups()) { group in
                            Section {
                                ForEach(group.sessions) { session in
                                    Button {
                                        store.inspectedSessionID = session.id
                                    } label: {
                                        HStack(spacing: 10) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(store.color(for: session))
                                                .frame(width: 4, height: 32)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(session.title)
                                                    .foregroundStyle(Theme.ink)
                                                Text(TimeText.range(start: session.start, end: session.end))
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.secondary)
                                            }
                                            Spacer()
                                            if session.needsMark() {
                                                Text("Open")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(Theme.ember)
                                            } else if session.isComplete {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Theme.tatami)
                                            }
                                        }
                                    }
                                    .listRowBackground(Theme.surface)
                                }
                            } header: {
                                Text(group.day.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
