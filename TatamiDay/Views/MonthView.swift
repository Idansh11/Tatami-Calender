import SwiftUI

struct MonthView: View {
    @Environment(AppStore.self) private var store
    var onCreate: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let calendar = Calendar.current
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button {
                        store.shiftSelection(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Previous month")

                    Text(store.selectedDay.formatted(.dateTime.month(.wide).year()))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)

                    Button {
                        store.shiftSelection(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Next month")
                }
                .foregroundStyle(Theme.ink)

                HStack(spacing: 6) {
                    ForEach(weekdaySymbols(calendar), id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(cells(calendar)) { cell in
                        if let day = cell.day {
                            dayCell(day, calendar: calendar)
                        } else {
                            Color.clear.frame(height: 78)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 24)
        }
    }

    private func dayCell(_ day: Date, calendar: Calendar) -> some View {
        let sessions = store.sessionsStarting(on: day)
        let selected = calendar.isDate(day, inSameDayAs: store.selectedDay)
        let today = calendar.isDateInToday(day)
        let shown = Array(sessions.prefix(4))
        return Button {
            store.selectedDay = day
            store.calendarMode = .day
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(day.formatted(.dateTime.day()))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(today ? Theme.tatami : Theme.ink)
                ForEach(shown) { session in
                    Capsule()
                        .fill(store.color(for: session).opacity(session.isComplete ? 0.45 : 1))
                        .frame(height: 4)
                }
                if sessions.count > shown.count {
                    Text("+\(sessions.count - shown.count)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(6)
            .frame(maxWidth: .infinity, minHeight: 78, alignment: .topLeading)
            .background(
                selected ? Theme.tatami.opacity(0.16) : Theme.surface,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(today ? Theme.tatami : Color.clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open day", systemImage: "calendar") {
                store.selectedDay = day
                store.calendarMode = .day
            }
            Button("Add session", systemImage: "plus") {
                let start = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: day) ?? day
                onCreate(start)
            }
        }
        .accessibilityLabel(accessibilityLabel(day, sessions: sessions))
    }

    private func accessibilityLabel(_ day: Date, sessions: [Session]) -> String {
        let title = day.formatted(.dateTime.weekday(.wide).month(.wide).day())
        if sessions.isEmpty { return "\(title), empty" }
        return "\(title), \(sessions.count) sessions"
    }

    private func weekdaySymbols(_ calendar: Calendar) -> [String] {
        let symbols = calendar.shortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(start + $0) % 7] }
    }

    private func cells(_ calendar: Calendar) -> [MonthCell] {
        let parts = calendar.dateComponents([.year, .month], from: store.selectedDay)
        guard let start = calendar.date(from: parts),
              let range = calendar.range(of: .day, in: .month, for: start) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: start)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        var cells: [MonthCell] = (0..<leading).map { MonthCell(id: "blank-\($0)", day: nil) }
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: start) {
                cells.append(MonthCell(id: "day-\(date.timeIntervalSinceReferenceDate)", day: date))
            }
        }
        return cells
    }
}

private struct MonthCell: Identifiable {
    let id: String
    let day: Date?
}
