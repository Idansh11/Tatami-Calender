import Foundation

struct DayPlacement: Identifiable, Equatable {
    let sessionID: UUID
    let startMinute: CGFloat
    let endMinute: CGFloat
    let column: Int
    let columnCount: Int

    var id: UUID { sessionID }
}

enum TimelineLayout {
    static func placements(for sessions: [Session], on day: Date, calendar: Calendar = .current) -> [DayPlacement] {
        let slices: [(UUID, CGFloat, CGFloat)] = sessions.compactMap { session in
            guard let range = minuteRange(session, on: day, calendar: calendar) else { return nil }
            return (session.id, range.0, range.1)
        }
        return assignColumns(slices)
    }

    static func minuteRange(_ session: Session, on day: Date, calendar: Calendar = .current) -> (CGFloat, CGFloat)? {
        let dayStart = calendar.startOfDay(for: day)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
        if session.end <= dayStart || session.start >= dayEnd { return nil }
        let clipStart = max(session.start, dayStart)
        let clipEnd = min(session.end, dayEnd)
        let startMinute = CGFloat(clipStart.timeIntervalSince(dayStart) / 60)
        let endMinute = CGFloat(clipEnd.timeIntervalSince(dayStart) / 60)
        guard endMinute - startMinute >= 1 else { return nil }
        return (startMinute, min(endMinute, 24 * 60))
    }

    private static func assignColumns(_ items: [(UUID, CGFloat, CGFloat)]) -> [DayPlacement] {
        let sorted = items.sorted { lhs, rhs in
            if lhs.1 == rhs.1 { return lhs.2 > rhs.2 }
            return lhs.1 < rhs.1
        }
        var placements: [DayPlacement] = []
        var index = 0
        while index < sorted.count {
            var cluster = [sorted[index]]
            var clusterEnd = sorted[index].2
            var next = index + 1
            while next < sorted.count, sorted[next].1 < clusterEnd - 0.01 {
                cluster.append(sorted[next])
                clusterEnd = max(clusterEnd, sorted[next].2)
                next += 1
            }

            var columnEnds: [CGFloat] = []
            var assigned: [(UUID, CGFloat, CGFloat, Int)] = []
            for item in cluster {
                if let column = columnEnds.firstIndex(where: { $0 <= item.1 + 0.01 }) {
                    columnEnds[column] = item.2
                    assigned.append((item.0, item.1, item.2, column))
                } else {
                    columnEnds.append(item.2)
                    assigned.append((item.0, item.1, item.2, columnEnds.count - 1))
                }
            }
            let count = max(columnEnds.count, 1)
            for item in assigned {
                placements.append(
                    DayPlacement(
                        sessionID: item.0,
                        startMinute: item.1,
                        endMinute: item.2,
                        column: item.3,
                        columnCount: count
                    )
                )
            }
            index = next
        }
        return placements
    }
}
