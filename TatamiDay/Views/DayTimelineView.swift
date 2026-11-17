import SwiftUI

struct DayTimelineView: View {
    @Environment(AppStore.self) private var store
    var onCreate: (Date) -> Void
    var onDivide: (Date) -> Void
    var onOpen: (UUID) -> Void
    var onEdit: (UUID) -> Void

    @ScaledMetric(relativeTo: .caption) private var gutter: CGFloat = 58
    @State private var now = Date()

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    timeline(width: geo.size.width)
                        .padding(.bottom, 24)
                }
                .onAppear { scroll(proxy) }
                .onChange(of: store.selectedDay) { _, _ in scroll(proxy) }
                .onChange(of: store.settings.densityMinutes) { _, _ in scroll(proxy) }
            }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy) {
        let calendar = Calendar.current
        let hour: Int
        if calendar.isDateInToday(store.selectedDay) {
            hour = max(0, calendar.component(.hour, from: Date()) - 1)
        } else {
            hour = 7
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000)
            proxy.scrollTo(hour, anchor: .top)
        }
    }

    private func timeline(width: CGFloat) -> some View {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: store.selectedDay)
        let daySessions = store.sessions(on: day)
        let placements = TimelineLayout.placements(for: daySessions, on: day, calendar: calendar)
        let lookup = Dictionary(uniqueKeysWithValues: daySessions.map { ($0.id, $0) })
        let height = store.hourHeight * 24

        return ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    hourRow(hour, on: day)
                        .id(hour)
                }
            }
            ZStack(alignment: .topLeading) {
                ForEach(placements) { placement in
                    if let session = lookup[placement.sessionID] {
                        block(placement, session: session, width: width)
                    }
                }
            }
            .frame(width: width, height: height, alignment: .topLeading)

            nowLine(at: now, width: width)
                .allowsHitTesting(false)
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .background {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                Color.clear
                    .onAppear { now = context.date }
                    .onChange(of: context.date) { _, newDate in
                        now = newDate
                    }
            }
        }
    }

    private func hourRow(_ hour: Int, on day: Date) -> some View {
        let slotCount = max(1, 60 / store.slotMinutes)
        let slotHeight = store.hourHeight / CGFloat(slotCount)
        return HStack(alignment: .top, spacing: 0) {
            Text(hourLabel(hour, on: day))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Theme.secondary)
                .frame(width: gutter - 8, alignment: .trailing)
                .padding(.top, 4)
                .frame(width: gutter, height: store.hourHeight, alignment: .top)
                .contentShape(Rectangle())
                .contextMenu {
                    Button("Add at this hour", systemImage: "plus") {
                        onCreate(hourDate(hour, on: day))
                    }
                    Button("Divide this hour", systemImage: "rectangle.split.3x1") {
                        onDivide(hourDate(hour, on: day))
                    }
                }
                .accessibilityLabel(hourLabel(hour, on: day))
                .accessibilityAction(named: "Divide this hour") {
                    onDivide(hourDate(hour, on: day))
                }

            VStack(spacing: 0) {
                ForEach(0..<slotCount, id: \.self) { slot in
                    let date = slotDate(hour: hour, slot: slot, on: day)
                    Button {
                        onCreate(date)
                    } label: {
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .frame(height: slotHeight)
                            .overlay(alignment: .top) {
                                Rectangle()
                                    .fill(Theme.line)
                                    .frame(height: slot == 0 ? 1 : 0.5)
                            }
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add session at \(date.formatted(date: .omitted, time: .shortened))")
                }
            }
        }
        .frame(height: store.hourHeight)
    }

    private func block(_ placement: DayPlacement, session: Session, width: CGFloat) -> some View {
        let duration = max(placement.endMinute - placement.startMinute, 1)
        let height = max(36, duration * store.pointsPerMinute)
        let columnWidth = max(44, (width - gutter) / CGFloat(max(placement.columnCount, 1)) - 6)
        let x = gutter + 3 + CGFloat(placement.column) * (columnWidth + 6)
        let y = placement.startMinute * store.pointsPerMinute
        let color = store.color(for: session)
        let topic = store.topic(for: session)

        return Button {
            onOpen(session.id)
        } label: {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color)
                    .frame(width: 4)
                    .padding(.vertical, 6)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        SymbolIcon(name: topic?.symbol ?? "circle.fill")
                            .font(.caption2)
                        Text(session.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        if session.isComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(color)
                        }
                    }
                    if height > 50 {
                        Text(TimeText.range(start: session.start, end: session.end))
                            .font(.caption2)
                            .foregroundStyle(Theme.secondary)
                            .lineLimit(1)
                    }
                    if session.needsMark() && height > 70 {
                        Text("Mark done")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.ember)
                    } else if session.isLive() && height > 70 {
                        Text("Now")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Theme.gold)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .background(
                color.opacity(session.isComplete ? 0.10 : 0.18),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(session.needsMark() ? Theme.ember : color.opacity(0.5), lineWidth: session.needsMark() ? 1.5 : 1)
            }
            .opacity(session.isComplete ? 0.72 : 1)
        }
        .buttonStyle(.plain)
        .frame(width: columnWidth, height: height, alignment: .topLeading)
        .offset(x: x, y: y)
        .contextMenu {
            Button(session.isComplete ? "Mark not done" : "Mark done", systemImage: "checkmark.circle") {
                store.setComplete(session.id, complete: !session.isComplete)
            }
            Button("Edit", systemImage: "pencil") {
                onEdit(session.id)
            }
        }
        .accessibilityLabel(accessibilityText(session, topic: topic))
        .accessibilityHint("Opens the session")
    }

    @ViewBuilder
    private func nowLine(at date: Date, width: CGFloat) -> some View {
        let calendar = Calendar.current
        if calendar.isDate(store.selectedDay, inSameDayAs: date) {
            let minute = CGFloat(calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date))
            let y = minute * store.pointsPerMinute
            HStack(spacing: 6) {
                Circle().fill(Theme.gold).frame(width: 8, height: 8)
                Rectangle().fill(Theme.gold).frame(height: 2)
                Text("Now")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.gold)
            }
            .padding(.leading, gutter - 4)
            .frame(width: width, alignment: .leading)
            .offset(y: y)
            .accessibilityHidden(true)
        }
    }

    private func accessibilityText(_ session: Session, topic: Topic?) -> String {
        let state: String
        if session.isComplete {
            state = "done"
        } else if session.needsMark() {
            state = "needs to be marked done"
        } else if session.isLive() {
            state = "happening now"
        } else {
            state = "planned"
        }
        return "\(session.title), \(topic?.name ?? "session"), \(TimeText.range(start: session.start, end: session.end)), \(state)"
    }

    private func hourLabel(_ hour: Int, on day: Date) -> String {
        guard let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) else {
            return "\(hour)"
        }
        return date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated)))
    }

    private func hourDate(_ hour: Int, on day: Date) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }

    private func slotDate(hour: Int, slot: Int, on day: Date) -> Date {
        let minutes = hour * 60 + slot * store.slotMinutes
        let start = Calendar.current.startOfDay(for: day)
        return Calendar.current.date(byAdding: .minute, value: minutes, to: start) ?? day
    }
}
