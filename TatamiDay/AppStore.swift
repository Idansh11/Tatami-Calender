import AuthenticationServices
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AppStore {
    let runsLiveServices: Bool

    var phase: AuthPhase
    var topics: [Topic]
    var sessions: [Session]
    var settings: Settings
    var selectedDay: Date
    var calendarMode: CalendarMode
    var inspectedSessionID: UUID?
    var showOverdueSheet: Bool
    var alertMessage: String?
    var profileGivenName: String
    var profileFamilyName: String
    var profileEmail: String

    private let persists: Bool

    init(preview: Bool = false) {
        runsLiveServices = !preview
        persists = !preview
        topics = TopicLibrary.presets()
        sessions = []
        settings = Settings()
        selectedDay = Date()
        calendarMode = .day
        inspectedSessionID = nil
        showOverdueSheet = false
        alertMessage = nil
        profileGivenName = ""
        profileFamilyName = ""
        profileEmail = ""
        phase = .signedOut

        if preview {
            phase = .ready
            settings.didFinishOnboarding = true
            profileGivenName = "Idan"
            profileFamilyName = "Shoshany"
            profileEmail = AccessPolicy.allowedEmail
            addTrainingPlan()
            settings.overdueSnoozeUntil = Date().addingTimeInterval(60 * 60 * 24 * 30)
            alertMessage = nil
            return
        }

        loadFromDisk()
        restoreAccount()
        if runsLiveServices {
            Task { await NotificationScheduler.resync(self) }
        }
    }

    var athleteName: String {
        let full = "\(profileGivenName) \(profileFamilyName)".trimmingCharacters(in: .whitespacesAndNewlines)
        return full.isEmpty ? "Athlete" : full
    }

    var athleteShortName: String {
        profileGivenName.isEmpty ? "Athlete" : profileGivenName
    }

    var slotMinutes: Int {
        let allowed = [10, 15, 20, 30, 60]
        return allowed.contains(settings.densityMinutes) ? settings.densityMinutes : 30
    }

    var pointsPerMinute: CGFloat {
        switch slotMinutes {
        case 10: return 4.4
        case 15: return 3.0
        case 20: return 2.4
        case 60: return 1.6
        default: return 2.2
        }
    }

    var hourHeight: CGFloat { pointsPerMinute * 60 }

    var overdueCount: Int { overdueSessions().count }

    var shouldPromptOverdue: Bool {
        overdueCount > 0 && (settings.overdueSnoozeUntil ?? .distantPast) <= Date()
    }

    func topic(for id: UUID) -> Topic? {
        topics.first { $0.id == id }
    }

    func topic(for session: Session) -> Topic? {
        topic(for: session.topicID)
    }

    func colorHex(for session: Session) -> String {
        session.colorHex ?? topic(for: session.topicID)?.colorHex ?? "2F8F62"
    }

    func color(for session: Session) -> Color {
        Color(hex: colorHex(for: session))
    }

    func topicsForPicker() -> [Topic] {
        topics.sorted { lhs, rhs in
            let left = TopicGroup.order.firstIndex(of: lhs.group) ?? 99
            let right = TopicGroup.order.firstIndex(of: rhs.group) ?? 99
            if left != right { return left < right }
            return lhs.sortIndex < rhs.sortIndex
        }
    }

    func groupedTopics(filter: String?) -> [(String, [Topic])] {
        let source = topics.filter { filter == nil || $0.group == filter }
        let groups = Dictionary(grouping: source, by: \.group)
        let keys = groups.keys.sorted {
            (TopicGroup.order.firstIndex(of: $0) ?? 99) < (TopicGroup.order.firstIndex(of: $1) ?? 99)
        }
        return keys.map { key in
            (key, (groups[key] ?? []).sorted { $0.sortIndex < $1.sortIndex })
        }
    }

    func sessions(on day: Date, calendar: Calendar = .current) -> [Session] {
        sessions
            .filter { TimelineLayout.minuteRange($0, on: day, calendar: calendar) != nil }
            .sorted { $0.start < $1.start }
    }

    func sessionsStarting(on day: Date, calendar: Calendar = .current) -> [Session] {
        sessions
            .filter { calendar.isDate($0.start, inSameDayAs: day) }
            .sorted { $0.start < $1.start }
    }

    func overdueSessions(at date: Date = Date()) -> [Session] {
        sessions.filter { $0.needsMark(at: date) }.sorted { $0.end < $1.end }
    }

    func upcomingSessions(limit: Int = 4) -> [Session] {
        let now = Date()
        return Array(
            sessions
                .filter { !$0.isComplete && $0.end > now }
                .sorted { $0.start < $1.start }
                .prefix(limit)
        )
    }

    func plannedMinutes(on day: Date, calendar: Calendar = .current) -> Int {
        sessionsStarting(on: day, calendar: calendar).reduce(0) { $0 + $1.durationMinutes }
    }

    func completedMinutes(on day: Date, calendar: Calendar = .current) -> Int {
        sessionsStarting(on: day, calendar: calendar)
            .filter(\.isComplete)
            .reduce(0) { $0 + $1.durationMinutes }
    }

    func currentStreak(calendar: Calendar = .current) -> Int {
        var day = calendar.startOfDay(for: Date())
        let trainedToday = sessions.contains { $0.isComplete && calendar.isDate($0.start, inSameDayAs: day) }
        if !trainedToday {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while count < 400 {
            let trained = sessions.contains { $0.isComplete && calendar.isDate($0.start, inSameDayAs: day) }
            if !trained { break }
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    func daysInSelectedWeek(calendar: Calendar = .current) -> [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: selectedDay) else { return [selectedDay] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    func topicMinutesThisWeek(calendar: Calendar = .current) -> [TopicMinutes] {
        let days = daysInSelectedWeek(calendar: calendar)
        var totals: [UUID: Int] = [:]
        for day in days {
            for session in sessionsStarting(on: day, calendar: calendar) where session.isComplete {
                totals[session.topicID, default: 0] += session.durationMinutes
            }
        }
        return totals.compactMap { id, minutes in
            guard let topic = topic(for: id) else { return nil }
            return TopicMinutes(topic: topic, minutes: minutes)
        }
        .sorted { $0.minutes > $1.minutes }
    }

    func historyGroups(calendar: Calendar = .current) -> [DayGroup] {
        let now = Date()
        let past = sessions.filter { $0.end < now || $0.isComplete }
        let grouped = Dictionary(grouping: past) { calendar.startOfDay(for: $0.start) }
        return grouped
            .map { day, items in
                DayGroup(day: day, sessions: items.sorted { $0.start < $1.start })
            }
            .sorted { $0.day > $1.day }
    }

    func suggestedStart(calendar: Calendar = .current) -> Date {
        let day = calendar.startOfDay(for: selectedDay)
        if calendar.isDateInToday(selectedDay) {
            let hour = calendar.component(.hour, from: Date())
            let minute = calendar.component(.minute, from: Date())
            let snapped = minute / slotMinutes * slotMinutes
            return calendar.date(bySettingHour: hour, minute: snapped, second: 0, of: day) ?? day
        }
        return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: day) ?? day
    }

    func suggestedHour(calendar: Calendar = .current) -> Date {
        let start = suggestedStart(calendar: calendar)
        let hour = calendar.component(.hour, from: start)
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: start) ?? start
    }

    func shiftSelection(by direction: Int, calendar: Calendar = .current) {
        let component: Calendar.Component
        let amount: Int
        switch calendarMode {
        case .day:
            component = .day
            amount = direction
        case .week:
            component = .day
            amount = direction * 7
        case .month:
            component = .month
            amount = direction
        }
        if let next = calendar.date(byAdding: component, value: amount, to: selectedDay) {
            selectedDay = next
        }
    }

    func makeDraft(for route: EditorRoute) -> SessionDraft {
        switch route {
        case .create(let start):
            let topicID = topics.first?.id ?? TopicID.judo
            return SessionDraft(
                id: UUID(),
                seriesID: nil,
                title: "",
                topicID: topicID,
                start: start,
                durationMinutes: max(slotMinutes, 15),
                notes: "",
                place: "",
                useCustomColor: false,
                colorHex: topic(for: topicID)?.colorHex ?? "2F8F62",
                wantsReminder: true,
                leadMinutes: settings.defaultLeadMinutes,
                requiresCompletion: true,
                isComplete: false,
                completedAt: nil,
                snoozedUntil: nil,
                repeatRule: .never,
                isNew: true
            )
        case .edit(let id):
            guard let session = sessions.first(where: { $0.id == id }) else {
                return makeDraft(for: .create(selectedDay))
            }
            return SessionDraft(
                id: session.id,
                seriesID: session.seriesID,
                title: session.title,
                topicID: session.topicID,
                start: session.start,
                durationMinutes: session.durationMinutes,
                notes: session.notes,
                place: session.place,
                useCustomColor: session.colorHex != nil,
                colorHex: session.colorHex ?? (topic(for: session.topicID)?.colorHex ?? "2F8F62"),
                wantsReminder: session.leadMinutes != nil,
                leadMinutes: session.leadMinutes ?? settings.defaultLeadMinutes,
                requiresCompletion: session.requiresCompletion,
                isComplete: session.isComplete,
                completedAt: session.completedAt,
                snoozedUntil: session.snoozedUntil,
                repeatRule: .never,
                isNew: false
            )
        }
    }

    func saveNew(draft: SessionDraft) {
        var draft = normalized(draft)
        let starts = occurrenceStarts(from: draft.start, rule: draft.repeatRule)
        let series = draft.repeatRule == .never ? nil : UUID()
        var made: [Session] = []
        for (index, start) in starts.enumerated() {
            var session = draft.makeSession()
            session.id = index == 0 ? draft.id : UUID()
            session.seriesID = series
            session.start = start
            session.isComplete = false
            session.completedAt = nil
            session.snoozedUntil = nil
            made.append(session)
        }
        sessions.append(contentsOf: made)
        commit()
    }

    func saveExisting(draft: SessionDraft, scope: SeriesScope) {
        guard let original = sessions.first(where: { $0.id == draft.id }) else { return }
        let edited = normalized(draft).makeSession()
        if scope == .one || edited.seriesID == nil {
            var single = edited
            if scope == .one { single.seriesID = nil }
            replace(single)
            return
        }
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: edited.start)
        var next = sessions
        for index in next.indices {
            guard next[index].seriesID == edited.seriesID else { continue }
            guard next[index].id == edited.id || next[index].start >= original.start else { continue }
            var parts = calendar.dateComponents([.year, .month, .day], from: next[index].start)
            parts.hour = time.hour
            parts.minute = time.minute
            next[index].start = calendar.date(from: parts) ?? next[index].start
            next[index].title = edited.title
            next[index].topicID = edited.topicID
            next[index].durationMinutes = edited.durationMinutes
            next[index].notes = edited.notes
            next[index].place = edited.place
            next[index].colorHex = edited.colorHex
            next[index].leadMinutes = edited.leadMinutes
            next[index].requiresCompletion = edited.requiresCompletion
        }
        sessions = next
        commit()
    }

    func delete(sessionID: UUID, scope: SeriesScope) {
        guard let session = sessions.first(where: { $0.id == sessionID }) else { return }
        if scope == .following, let series = session.seriesID {
            sessions.removeAll { $0.seriesID == series && ($0.id == session.id || $0.start >= session.start) }
        } else {
            sessions.removeAll { $0.id == sessionID }
        }
        if inspectedSessionID == sessionID {
            inspectedSessionID = nil
        }
        commit()
    }

    func setComplete(_ id: UUID, complete: Bool) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        var next = sessions
        next[index].isComplete = complete
        next[index].completedAt = complete ? Date() : nil
        if complete { next[index].snoozedUntil = nil }
        sessions = next
        commit()
    }

    func snoozeSession(_ id: UUID, minutes: Int = 30) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        var next = sessions
        next[index].snoozedUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
        sessions = next
        commit()
    }

    func divideHour(start: Date, parts: Int, topicID: UUID, titles: [String]) {
        let safeParts = max(2, min(parts, 6))
        let length = max(5, 60 / safeParts)
        let topicName = topic(for: topicID)?.name ?? "Session"
        var made: [Session] = []
        for index in 0..<safeParts {
            let slot = start.addingTimeInterval(TimeInterval(index * length * 60))
            let raw = index < titles.count ? titles[index].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            made.append(
                Session(
                    id: UUID(),
                    seriesID: nil,
                    title: raw.isEmpty ? topicName : raw,
                    topicID: topicID,
                    start: slot,
                    durationMinutes: length,
                    notes: "",
                    place: "",
                    colorHex: nil,
                    leadMinutes: settings.defaultLeadMinutes,
                    requiresCompletion: true,
                    isComplete: false,
                    completedAt: nil
                )
            )
        }
        sessions.append(contentsOf: made)
        commit()
    }

    func addTrainingPlan(around date: Date = Date()) {
        let calendar = Calendar.current
        let monday = trainingMonday(containing: date, calendar: calendar)
        let series = UUID()
        var created: [Session] = []
        for item in TrainingPlan.items {
            guard let day = calendar.date(byAdding: .day, value: item.weekday, to: monday),
                  let start = calendar.date(bySettingHour: item.hour, minute: item.minute, second: 0, of: day) else {
                continue
            }
            let exists = sessions.contains {
                abs($0.start.timeIntervalSince(start)) < 60 && $0.title == item.title
            }
            if exists { continue }
            created.append(
                Session(
                    id: UUID(),
                    seriesID: series,
                    title: item.title,
                    topicID: item.topicID,
                    start: start,
                    durationMinutes: item.duration,
                    notes: item.notes,
                    place: item.place,
                    colorHex: nil,
                    leadMinutes: settings.defaultLeadMinutes,
                    requiresCompletion: true,
                    isComplete: false,
                    completedAt: nil
                )
            )
        }
        guard !created.isEmpty else {
            alertMessage = "This week already has that training plan."
            return
        }
        sessions.append(contentsOf: created)
        commit()
        alertMessage = "Added \(created.count) sessions to this week."
    }

    func addTopic(name: String, symbol: String, hex: String, group: String, ideas: [String]) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            alertMessage = "Give the topic a name."
            return
        }
        let topic = Topic(
            id: UUID(),
            name: trimmed,
            symbol: symbol,
            colorHex: hex,
            group: group.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Custom" : group,
            isPreset: false,
            sortIndex: (topics.map(\.sortIndex).max() ?? 0) + 1,
            titleIdeas: ideas
        )
        topics.append(topic)
        commit()
    }

    func updateTopic(_ topic: Topic) {
        guard let index = topics.firstIndex(where: { $0.id == topic.id }) else { return }
        var next = topics
        var edited = topic
        edited.name = edited.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if edited.name.isEmpty { return }
        next[index] = edited
        topics = next
        commit()
    }

    func deleteTopic(_ id: UUID) {
        guard let topic = topics.first(where: { $0.id == id }) else { return }
        if topic.isPreset {
            alertMessage = "Built-in topics stay in the library. You can still change the color."
            return
        }
        let count = sessions.filter { $0.topicID == id }.count
        if count > 0 {
            alertMessage = "\(count) session\(count == 1 ? "" : "s") still use \(topic.name)."
            return
        }
        topics.removeAll { $0.id == id }
        commit()
    }

    func restorePreset(_ id: UUID) {
        guard let original = TopicLibrary.presets().first(where: { $0.id == id }),
              let index = topics.firstIndex(where: { $0.id == id }) else { return }
        var next = topics
        next[index].name = original.name
        next[index].symbol = original.symbol
        next[index].colorHex = original.colorHex
        next[index].titleIdeas = original.titleIdeas
        topics = next
        commit()
    }

    func updateSettings(_ change: (inout Settings) -> Void) {
        var next = settings
        change(&next)
        let allowed = [10, 15, 20, 30, 60]
        if !allowed.contains(next.densityMinutes) {
            next.densityMinutes = 30
        }
        settings = next
        commit()
    }

    func snoozeOverduePrompt(minutes: Int) {
        var next = settings
        next.overdueSnoozeUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
        settings = next
        save()
    }

    func presentOverdueIfNeeded() {
        guard runsLiveServices, phase == .ready, settings.didFinishOnboarding, shouldPromptOverdue, !showOverdueSheet else {
            return
        }
        showOverdueSheet = true
        snoozeOverduePrompt(minutes: 60)
    }

    func exportData() -> Data? {
        let file = StoreFile(version: 1, topics: topics, sessions: sessions, settings: settings)
        return try? TatamiJSON.encoder(pretty: true).encode(file)
    }

    func importData(_ data: Data) {
        do {
            let file = try TatamiJSON.decoder.decode(StoreFile.self, from: data)
            guard file.version >= 1 else {
                alertMessage = "That file is not a Tatami Day backup."
                return
            }
            for topic in file.topics {
                if let index = topics.firstIndex(where: { $0.id == topic.id }) {
                    topics[index] = topic
                } else {
                    topics.append(topic)
                }
            }
            for session in file.sessions {
                if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                    sessions[index] = session
                } else {
                    sessions.append(session)
                }
            }
            let keepOnboarding = settings.didFinishOnboarding
            settings = file.settings
            if keepOnboarding { settings.didFinishOnboarding = true }
            mergeMissingPresets()
            commit()
            alertMessage = "Imported \(file.sessions.count) sessions."
        } catch {
            alertMessage = "That file is not a Tatami Day backup."
        }
    }

    func handle(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            handle(authorization: authorization)
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return
            }
            alertMessage = "Sign in with Apple did not finish. Try again."
        }
    }

    func signOut() {
        KeychainStore.deleteAll()
        profileEmail = ""
        profileGivenName = ""
        profileFamilyName = ""
        inspectedSessionID = nil
        showOverdueSheet = false
        phase = .signedOut
        if runsLiveServices {
            Task { await NotificationScheduler.removeAll() }
        }
    }

    func deleteAccount() {
        sessions = []
        topics = TopicLibrary.presets()
        settings = Settings(
            defaultLeadMinutes: 15,
            densityMinutes: 30,
            appearance: settings.appearance,
            didFinishOnboarding: false,
            overdueSnoozeUntil: nil
        )
        save()
        signOut()
    }

    func handleNotification(action: String, sessionID: String?, kind: String?) {
        if kind == "summary" || sessionID == nil && kind == "summary" {
            showOverdueSheet = true
            return
        }
        guard let sessionID, let id = UUID(uuidString: sessionID),
              let session = sessions.first(where: { $0.id == id }) else {
            if kind == "summary" { showOverdueSheet = true }
            return
        }
        switch action {
        case "tatami.done":
            setComplete(id, complete: true)
        case "tatami.snooze":
            snoozeSession(id)
        default:
            selectedDay = session.start
            calendarMode = .day
            inspectedSessionID = id
        }
    }

    private func handle(authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            alertMessage = "Apple did not return a credential."
            return
        }
        let tokenEmail = IdentityToken.email(from: credential.identityToken)
        let email = credential.email ?? tokenEmail
        let privateRelay = IdentityToken.isPrivateRelay(credential.identityToken)
            || (email?.lowercased().contains("privaterelay.appleid.com") ?? false)

        if privateRelay {
            phase = .denied("Hide My Email cannot open this private copy. In Settings, tap your name, then Sign in with Apple, then Tatami Day, then Stop Using Apple ID. Sign in again and choose Share My Email.")
            return
        }
        guard let email, AccessPolicy.allows(email: email) else {
            if let email {
                phase = .denied("This copy of Tatami Day only opens for \(AccessPolicy.allowedEmail). Apple shared \(email).")
            } else {
                phase = .denied("Apple did not share an email address. Sign in again and choose Share My Email for \(AccessPolicy.allowedEmail). If Hide My Email was used before, remove Tatami Day from Sign in with Apple in Settings and try again.")
            }
            return
        }

        KeychainStore.set(credential.user, account: KeychainAccount.userID)
        KeychainStore.set(email, account: KeychainAccount.email)
        if let given = credential.fullName?.givenName, !given.isEmpty {
            KeychainStore.set(given, account: KeychainAccount.givenName)
            profileGivenName = given
        }
        if let family = credential.fullName?.familyName, !family.isEmpty {
            KeychainStore.set(family, account: KeychainAccount.familyName)
            profileFamilyName = family
        }
        profileEmail = email
        phase = .ready
        if runsLiveServices {
            Task { await NotificationScheduler.resync(self) }
        }
    }

    private func restoreAccount() {
        let email = KeychainStore.get(KeychainAccount.email) ?? ""
        let userID = KeychainStore.get(KeychainAccount.userID)
        profileEmail = email
        profileGivenName = KeychainStore.get(KeychainAccount.givenName) ?? ""
        profileFamilyName = KeychainStore.get(KeychainAccount.familyName) ?? ""
        guard let userID, AccessPolicy.allows(email: email) else {
            if userID != nil || !email.isEmpty {
                KeychainStore.deleteAll()
                profileEmail = ""
                profileGivenName = ""
                profileFamilyName = ""
            }
            phase = .signedOut
            return
        }
        phase = .ready
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
            Task { @MainActor in
                if state == .revoked || state == .notFound {
                    self.signOut()
                }
            }
        }
    }

    private func normalized(_ draft: SessionDraft) -> SessionDraft {
        var draft = draft
        let trimmed = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.title = trimmed.isEmpty ? (topic(for: draft.topicID)?.name ?? "Session") : trimmed
        draft.durationMinutes = min(360, max(5, draft.durationMinutes))
        return draft
    }

    private func replace(_ session: Session) {
        var next = sessions
        if let index = next.firstIndex(where: { $0.id == session.id }) {
            next[index] = session
        } else {
            next.append(session)
        }
        sessions = next
        commit()
    }

    private func occurrenceStarts(from start: Date, rule: RepeatRule, calendar: Calendar = .current) -> [Date] {
        guard rule != .never else { return [start] }
        guard let horizon = calendar.date(byAdding: .day, value: 56, to: start) else { return [start] }
        var dates = [start]
        var cursor = start
        var steps = 0
        while dates.count < 56 && steps < 90 {
            steps += 1
            let step = rule == .weekly ? 7 : 1
            guard let next = calendar.date(byAdding: .day, value: step, to: cursor) else { break }
            cursor = next
            if cursor > horizon { break }
            if rule == .weekdays {
                let weekday = calendar.component(.weekday, from: cursor)
                if weekday == 1 || weekday == 7 { continue }
            }
            dates.append(cursor)
        }
        return dates
    }

    private func trainingMonday(containing date: Date, calendar: Calendar) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let daysFromMonday = (weekday + 5) % 7
        let day = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: day) ?? day
    }

    private func commit() {
        guard persists else { return }
        save()
        if runsLiveServices {
            Task { await NotificationScheduler.resync(self) }
        }
    }

    private func save() {
        guard persists, let url = try? Self.storeURL() else { return }
        let file = StoreFile(version: 1, topics: topics, sessions: sessions, settings: settings)
        guard let data = try? TatamiJSON.encoder(pretty: false).encode(file) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func loadFromDisk() {
        guard let url = try? Self.storeURL(), FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            let file = try TatamiJSON.decoder.decode(StoreFile.self, from: data)
            topics = file.topics
            sessions = file.sessions
            settings = file.settings
            for index in sessions.indices where sessions[index].durationMinutes < 5 {
                sessions[index].durationMinutes = 5
            }
            mergeMissingPresets()
        } catch {
            let bad = url.deletingLastPathComponent().appendingPathComponent("store-unreadable-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.moveItem(at: url, to: bad)
        }
    }

    private func mergeMissingPresets() {
        let existing = Set(topics.map(\.id))
        for preset in TopicLibrary.presets() where !existing.contains(preset.id) {
            topics.append(preset)
        }
        topics.sort { $0.sortIndex < $1.sortIndex }
    }

    private static func storeURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = base.appendingPathComponent("TatamiDay", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("store.json")
    }
}
