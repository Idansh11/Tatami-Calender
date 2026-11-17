import SwiftUI

struct WeekColumnsView: View {
    @Environment(AppStore.self) private var store
    var onCreate: (Date) -> Void
    var onOpen: (UUID) -> Void

    private let gutter: CGFloat = 36
    private let hourHeight: CGFloat = 52

    var body: some View {
        VStack(spacing: 8) {
            dayHeader
            GeometryReader { geo in
                ScrollView {
                    grid(width: geo.size.width)
                        .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dayHeader: some View {
        let calendar = Calendar.current
        return HStack(spacing: 0) {
            Color.clear.frame(width: gutter, height: 44)
            ForEach(store.daysInSelectedWeek(), id: \.self) { day in
                let selected = calendar.isDate(day, inSameDayAs: store.selectedDay)
                Button {
                    store.selectedDay = day
                    store.calendarMode = .day
                } label: {
                    VStack(spacing: 2) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2.weight(.semibold))
                        Text(day.formatted(.dateTime.day()))
                            .font(.caption.weight(.bold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(selected ? Theme.tatami : Theme.ink)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open \(day.formatted(.dateTime.weekday(.wide).month().day()))")
            }
        }
        .padding(.horizontal, 4)
    }

    private func grid(width: CGFloat) -> some View {
        let days = store.daysInSelectedWeek()
        let columnWidth = max(28, (width - gutter) / 7)
        let slots = days.enumerated().flatMap { index, day in
            (0..<24).map { hour in
                WeekSlot(dayIndex: index, hour: hour, day: day)
            }
        }
        var blocks: [WeekBlock] = []
        for (index, day) in days.enumerated() {
            let sessions = store.sessions(on: day)
            let lookup = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
            for placement in TimelineLayout.placements(for: sessions, on: day) {
                if let session = lookup[placement.sessionID] {
                    blocks.append(WeekBlock(dayIndex: index, placement: placement, session: session))
                }
            }
        }
        let height = hourHeight * 24

        return ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    HStack(spacing: 0) {
                        Text(hourLabel(hour))
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(Theme.secondary)
                            .frame(width: gutter, alignment: .topTrailing)
                            .padding(.trailing, 4)
                        Rectangle()
                            .fill(Theme.line)
                            .frame(height: 1)
                            .padding(.top, 6)
                    }
                    .frame(height: hourHeight, alignment: .top)
                }
            }

            ZStack(alignment: .topLeading) {
                ForEach(slots) { slot in
                    Button {
                        onCreate(date(slot.day, hour: slot.hour))
                    } label: {
                        Color.clear
                            .frame(width: columnWidth - 2, height: hourHeight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .offset(
                        x: gutter + CGFloat(slot.dayIndex) * columnWidth,
                        y: CGFloat(slot.hour) * hourHeight
                    )
                    .accessibilityLabel("Add on \(slot.day.formatted(.dateTime.weekday(.abbreviated))) at \(hourLabel(slot.hour))")
                }
            }
            .frame(width: width, height: height, alignment: .topLeading)
            .allowsHitTesting(true)

            ZStack(alignment: .topLeading) {
                ForEach(blocks) { block in
                    weekBlock(block, columnWidth: columnWidth)
                }
            }
            .frame(width: width, height: height, alignment: .topLeading)
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }

    private func weekBlock(_ block: WeekBlock, columnWidth: CGFloat) -> some View {
        let placement = block.placement
        let session = block.session
        let scale = hourHeight / 60
        let height = max(18, (placement.endMinute - placement.startMinute) * scale)
        let width = max(18, (columnWidth - 3) / CGFloat(max(placement.columnCount, 1)) - 2)
        let x = gutter + CGFloat(block.dayIndex) * columnWidth + 2 + CGFloat(placement.column) * (width + 2)
        let y = placement.startMinute * scale
        let color = store.color(for: session)
        let topic = store.topic(for: session)
        return Button {
            onOpen(session.id)
        } label: {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(color.opacity(session.isComplete ? 0.45 : 0.92))
                .overlay(alignment: .topLeading) {
                    if height > 28 {
                        Text(session.title)
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                            .foregroundStyle(Contrast.ink(on: store.colorHex(for: session)))
                            .lineLimit(2)
                            .padding(3)
                    }
                }
                .overlay {
                    if session.needsMark() {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(Theme.ember, lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(.plain)
        .frame(width: width, height: height, alignment: .topLeading)
        .offset(x: x, y: y)
        .accessibilityLabel("\(session.title), \(topic?.name ?? ""), \(TimeText.range(start: session.start, end: session.end))")
    }

    private func hourLabel(_ hour: Int) -> String {
        guard let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) else {
            return "\(hour)"
        }
        return date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated)))
    }

    private func date(_ day: Date, hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }
}

private struct WeekSlot: Identifiable {
    var dayIndex: Int
    var hour: Int
    var day: Date
    var id: String { "\(dayIndex)-\(hour)" }
}

private struct WeekBlock: Identifiable {
    var dayIndex: Int
    var placement: DayPlacement
    var session: Session
    var id: String { "\(dayIndex)-\(session.id.uuidString)" }
}
