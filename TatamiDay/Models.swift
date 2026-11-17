import Foundation

enum TopicID {
    static let judo = UUID(uuidString: "A1000001-0000-4000-8000-000000000001")!
    static let randori = UUID(uuidString: "A1000001-0000-4000-8000-000000000002")!
    static let newaza = UUID(uuidString: "A1000001-0000-4000-8000-000000000003")!
    static let sparring = UUID(uuidString: "A1000001-0000-4000-8000-000000000004")!
    static let technique = UUID(uuidString: "A1000001-0000-4000-8000-000000000005")!
    static let competition = UUID(uuidString: "A1000001-0000-4000-8000-000000000006")!
    static let run = UUID(uuidString: "A1000001-0000-4000-8000-000000000007")!
    static let walk = UUID(uuidString: "A1000001-0000-4000-8000-000000000008")!
    static let conditioning = UUID(uuidString: "A1000001-0000-4000-8000-000000000009")!
    static let strength = UUID(uuidString: "A1000001-0000-4000-8000-00000000000A")!
    static let power = UUID(uuidString: "A1000001-0000-4000-8000-00000000000B")!
    static let grip = UUID(uuidString: "A1000001-0000-4000-8000-00000000000C")!
    static let mobility = UUID(uuidString: "A1000001-0000-4000-8000-00000000000D")!
    static let warmup = UUID(uuidString: "A1000001-0000-4000-8000-00000000000E")!
    static let cooldown = UUID(uuidString: "A1000001-0000-4000-8000-00000000000F")!
    static let recovery = UUID(uuidString: "A1000001-0000-4000-8000-000000000010")!
    static let rehab = UUID(uuidString: "A1000001-0000-4000-8000-000000000011")!
    static let sport = UUID(uuidString: "A1000001-0000-4000-8000-000000000012")!
    static let nutrition = UUID(uuidString: "A1000001-0000-4000-8000-000000000013")!
    static let sleep = UUID(uuidString: "A1000001-0000-4000-8000-000000000014")!
    static let rest = UUID(uuidString: "A1000001-0000-4000-8000-000000000015")!
    static let mental = UUID(uuidString: "A1000001-0000-4000-8000-000000000016")!
}

enum TopicGroup {
    static let order = ["Combat", "Endurance", "Strength", "Recovery", "Life", "Custom"]
}

struct Topic: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var symbol: String
    var colorHex: String
    var group: String
    var isPreset: Bool
    var sortIndex: Int
    var titleIdeas: [String]
}

struct Session: Identifiable, Codable, Equatable {
    var id: UUID
    var seriesID: UUID?
    var title: String
    var topicID: UUID
    var start: Date
    var durationMinutes: Int
    var notes: String
    var place: String
    var colorHex: String?
    var leadMinutes: Int?
    var requiresCompletion: Bool
    var isComplete: Bool
    var completedAt: Date?
    var snoozedUntil: Date? = nil

    var end: Date {
        start.addingTimeInterval(TimeInterval(durationMinutes) * 60)
    }

    func needsMark(at date: Date = Date()) -> Bool {
        requiresCompletion && !isComplete && end <= date
    }

    func isLive(at date: Date = Date()) -> Bool {
        date >= start && date < end
    }
}

enum AppearanceChoice: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

struct Settings: Codable, Equatable {
    var defaultLeadMinutes: Int = 15
    var densityMinutes: Int = 30
    var appearance: AppearanceChoice = .system
    var didFinishOnboarding: Bool = false
    var overdueSnoozeUntil: Date? = nil
}

struct StoreFile: Codable {
    var version: Int
    var topics: [Topic]
    var sessions: [Session]
    var settings: Settings
}

enum RepeatRule: String, CaseIterable, Identifiable, Codable {
    case never
    case daily
    case weekdays
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .never: "Does not repeat"
        case .daily: "Every day"
        case .weekdays: "Weekdays"
        case .weekly: "Every week"
        }
    }
}

enum SeriesScope {
    case one
    case following
}

enum EditorRoute: Identifiable, Equatable {
    case create(Date)
    case edit(UUID)

    var id: String {
        switch self {
        case .create(let date):
            "create-\(date.timeIntervalSinceReferenceDate)"
        case .edit(let id):
            "edit-\(id.uuidString)"
        }
    }
}

struct SessionLink: Identifiable, Equatable {
    let id: UUID
}

struct HourStart: Identifiable, Equatable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSinceReferenceDate }
}

struct TopicMinutes: Identifiable {
    var topic: Topic
    var minutes: Int
    var id: UUID { topic.id }
}

struct DayGroup: Identifiable {
    var day: Date
    var sessions: [Session]
    var id: Date { day }
}

enum CalendarMode: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }
}

enum AuthPhase: Equatable {
    case signedOut
    case denied(String)
    case ready
}

struct SessionDraft: Equatable {
    var id: UUID
    var seriesID: UUID?
    var title: String
    var topicID: UUID
    var start: Date
    var durationMinutes: Int
    var notes: String
    var place: String
    var useCustomColor: Bool
    var colorHex: String
    var wantsReminder: Bool
    var leadMinutes: Int
    var requiresCompletion: Bool
    var isComplete: Bool
    var completedAt: Date?
    var snoozedUntil: Date?
    var repeatRule: RepeatRule
    var isNew: Bool

    var end: Date {
        start.addingTimeInterval(TimeInterval(durationMinutes * 60))
    }

    func makeSession() -> Session {
        Session(
            id: id,
            seriesID: seriesID,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            topicID: topicID,
            start: start,
            durationMinutes: max(5, durationMinutes),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            place: place.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: useCustomColor ? colorHex : nil,
            leadMinutes: wantsReminder ? leadMinutes : nil,
            requiresCompletion: requiresCompletion,
            isComplete: isComplete,
            completedAt: completedAt,
            snoozedUntil: snoozedUntil
        )
    }
}

enum TatamiJSON {
    static func encoder(pretty: Bool) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = pretty ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        return encoder
    }

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

enum TopicLibrary {
    static func presets() -> [Topic] {
        var index = 0
        func make(
            _ id: UUID,
            _ name: String,
            _ symbol: String,
            _ hex: String,
            _ group: String,
            _ ideas: [String]
        ) -> Topic {
            let topic = Topic(
                id: id,
                name: name,
                symbol: symbol,
                colorHex: hex,
                group: group,
                isPreset: true,
                sortIndex: index,
                titleIdeas: ideas
            )
            index += 1
            return topic
        }

        return [
            make(TopicID.judo, "Judo", "figure.wrestling", "C23B2E", "Combat", ["Uchikomi", "Nagekomi", "Kata", "Grip fighting", "Footwork"]),
            make(TopicID.randori, "Randori", "figure.martial.arts", "8C2F39", "Combat", ["Standing randori", "Ground randori", "Competition randori"]),
            make(TopicID.newaza, "Newaza", "figure.wrestling", "A33B4A", "Combat", ["Turnovers", "Pins", "Escapes", "Transitions"]),
            make(TopicID.sparring, "Sparring", "bolt.fill", "D4537E", "Combat", ["Light sparring", "Hard sparring", "Situational"]),
            make(TopicID.technique, "Technique", "target", "E07A2F", "Combat", ["Throws", "Combinations", "Counters", "Drills"]),
            make(TopicID.competition, "Competition", "trophy.fill", "E2B15A", "Combat", ["Match prep", "Weigh-in", "Review", "Simulation"]),
            make(TopicID.run, "Run", "figure.run", "F08A5D", "Endurance", ["Easy run", "Tempo", "Intervals", "Long run", "Hills", "Strides"]),
            make(TopicID.walk, "Walk", "figure.walk", "2F8F62", "Endurance", ["Easy walk", "Recovery walk", "Hills walk"]),
            make(TopicID.conditioning, "Conditioning", "flame.fill", "C45C26", "Endurance", ["Circuits", "Intervals", "Row", "Sprints"]),
            make(TopicID.strength, "Strength", "dumbbell.fill", "3E6FD8", "Strength", ["Lower body", "Upper body", "Full body", "Pull"]),
            make(TopicID.power, "Power", "bolt.fill", "5B8DEF", "Strength", ["Jumps", "Med ball", "Contrast"]),
            make(TopicID.grip, "Grip", "hand.raised.fill", "5C6B8A", "Strength", ["Gi grips", "Hangs", "Farmer carry"]),
            make(TopicID.mobility, "Mobility", "figure.flexibility", "7A6FF0", "Recovery", ["Hips", "Shoulders", "Thoracic", "Neck"]),
            make(TopicID.warmup, "Warm-up", "sun.max.fill", "F2C14E", "Recovery", ["Movement prep", "Joints", "Pulse raiser"]),
            make(TopicID.cooldown, "Cooldown", "figure.cooldown", "6C8EBF", "Recovery", ["Breath", "Easy flush", "Stretch"]),
            make(TopicID.recovery, "Recovery", "leaf.fill", "3AAFA9", "Recovery", ["Off feet", "Nap", "Flush"]),
            make(TopicID.rehab, "Rehab", "cross.case.fill", "E15A3A", "Recovery", ["Prehab", "Physio homework", "Reload"]),
            make(TopicID.sport, "Sport", "sportscourt.fill", "C6A15B", "Life", ["Practice", "Match", "Skills"]),
            make(TopicID.nutrition, "Nutrition", "fork.knife", "6BAA45", "Life", ["Breakfast", "Lunch", "Dinner", "Fueling"]),
            make(TopicID.sleep, "Sleep", "moon.stars.fill", "3D4C73", "Life", ["Wind down", "Nap", "Night"]),
            make(TopicID.rest, "Rest day", "pause.circle.fill", "8A938C", "Life", ["Full rest", "Active rest"]),
            make(TopicID.mental, "Mental", "brain.head.profile", "9B7EDE", "Life", ["Visualization", "Breath work", "Video study"])
        ]
    }
}

enum TrainingPlan {
    struct Item {
        var weekday: Int
        var hour: Int
        var minute: Int
        var duration: Int
        var topicID: UUID
        var title: String
        var place: String
        var notes: String
    }

    static let items: [Item] = [
        Item(weekday: 0, hour: 6, minute: 30, duration: 40, topicID: TopicID.run, title: "Easy run", place: "Road", notes: "Conversational pace."),
        Item(weekday: 0, hour: 18, minute: 0, duration: 45, topicID: TopicID.judo, title: "Uchikomi", place: "Dojo", notes: "High volume, light throws."),
        Item(weekday: 0, hour: 18, minute: 45, duration: 45, topicID: TopicID.randori, title: "Standing randori", place: "Dojo", notes: ""),
        Item(weekday: 1, hour: 7, minute: 0, duration: 50, topicID: TopicID.strength, title: "Lower body", place: "Gym", notes: ""),
        Item(weekday: 1, hour: 18, minute: 30, duration: 60, topicID: TopicID.newaza, title: "Turnovers", place: "Dojo", notes: ""),
        Item(weekday: 2, hour: 6, minute: 30, duration: 30, topicID: TopicID.walk, title: "Recovery walk", place: "Road", notes: ""),
        Item(weekday: 2, hour: 12, minute: 15, duration: 20, topicID: TopicID.mobility, title: "Hips", place: "Home", notes: ""),
        Item(weekday: 2, hour: 18, minute: 0, duration: 75, topicID: TopicID.technique, title: "Throw combinations", place: "Dojo", notes: ""),
        Item(weekday: 3, hour: 6, minute: 45, duration: 35, topicID: TopicID.run, title: "Intervals", place: "Road", notes: ""),
        Item(weekday: 3, hour: 18, minute: 0, duration: 30, topicID: TopicID.judo, title: "Grip fighting", place: "Dojo", notes: ""),
        Item(weekday: 3, hour: 18, minute: 30, duration: 60, topicID: TopicID.randori, title: "Competition randori", place: "Dojo", notes: ""),
        Item(weekday: 4, hour: 7, minute: 0, duration: 45, topicID: TopicID.strength, title: "Full body", place: "Gym", notes: ""),
        Item(weekday: 4, hour: 17, minute: 30, duration: 15, topicID: TopicID.warmup, title: "Movement prep", place: "Dojo", notes: ""),
        Item(weekday: 4, hour: 17, minute: 45, duration: 30, topicID: TopicID.conditioning, title: "Circuits", place: "Gym", notes: ""),
        Item(weekday: 4, hour: 19, minute: 0, duration: 15, topicID: TopicID.cooldown, title: "Breath", place: "Home", notes: ""),
        Item(weekday: 5, hour: 10, minute: 0, duration: 40, topicID: TopicID.judo, title: "Kata", place: "Dojo", notes: ""),
        Item(weekday: 5, hour: 10, minute: 45, duration: 50, topicID: TopicID.randori, title: "Standing randori", place: "Dojo", notes: ""),
        Item(weekday: 5, hour: 11, minute: 40, duration: 30, topicID: TopicID.strength, title: "Pull", place: "Gym", notes: ""),
        Item(weekday: 5, hour: 17, minute: 0, duration: 25, topicID: TopicID.mental, title: "Video study", place: "Home", notes: ""),
        Item(weekday: 6, hour: 9, minute: 0, duration: 45, topicID: TopicID.walk, title: "Easy walk", place: "Road", notes: ""),
        Item(weekday: 6, hour: 11, minute: 0, duration: 40, topicID: TopicID.recovery, title: "Off feet", place: "Home", notes: ""),
        Item(weekday: 6, hour: 21, minute: 15, duration: 20, topicID: TopicID.sleep, title: "Wind down", place: "Home", notes: "")
    ]
}
