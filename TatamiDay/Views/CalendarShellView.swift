import SwiftUI

struct CalendarShellView: View {
    @Environment(AppStore.self) private var store
    @State private var editor: EditorRoute?
    @State private var hourToDivide: HourStart?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                Group {
                    switch store.calendarMode {
                    case .day:
                        DayTimelineView(
                            onCreate: { editor = .create($0) },
                            onDivide: { hourToDivide = HourStart(date: $0) },
                            onOpen: { store.inspectedSessionID = $0 },
                            onEdit: { editor = .edit($0) }
                        )
                    case .week:
                        WeekColumnsView(
                            onCreate: { editor = .create($0) },
                            onOpen: { store.inspectedSessionID = $0 }
                        )
                    case .month:
                        MonthView(onCreate: { editor = .create($0) })
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(item: $editor) { route in
            SessionEditorLoader(route: route)
                .presentationBackground(Theme.background)
        }
        .sheet(item: $hourToDivide) { hour in
            DivideHourSheet(hour: hour.date)
                .presentationBackground(Theme.background)
        }
    }

    private var modeBinding: Binding<CalendarMode> {
        Binding(
            get: { store.calendarMode },
            set: { store.calendarMode = $0 }
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("TATAMI DAY")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.tatami)
                Spacer()
                if !Calendar.current.isDateInToday(store.selectedDay) {
                    Button("Today") { store.selectedDay = Date() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.tatami)
                }
                addMenu
            }

            titleBlock

            if store.overdueCount > 0 {
                Button {
                    store.showOverdueSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("\(store.overdueCount) to mark done")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundStyle(Theme.ember)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(Theme.ember.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(store.overdueCount) sessions need to be marked done")
            }

            Picker("Calendar", selection: modeBinding) {
                Text("Day").tag(CalendarMode.day)
                Text("Week").tag(CalendarMode.week)
                Text("Month").tag(CalendarMode.month)
            }
            .pickerStyle(.segmented)

            if store.calendarMode == .day {
                densityChips
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var titleBlock: some View {
        switch store.calendarMode {
        case .day:
            VStack(alignment: .leading, spacing: 10) {
                dayTitle
                progress
                if store.plannedMinutes(on: store.selectedDay) == 0 {
                    Text("Tap a slot to add. Hold an hour to divide it.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondary)
                }
                weekStrip
            }
        case .week:
            VStack(alignment: .leading, spacing: 10) {
                weekTitle
                weekStrip
            }
        case .month:
            EmptyView()
        }
    }

    private var dayTitle: some View {
        HStack(spacing: 0) {
            shiftButton(direction: -1)
            Text(store.selectedDay.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
            shiftButton(direction: 1)
        }
    }

    private var weekTitle: some View {
        let days = store.daysInSelectedWeek()
        return HStack(spacing: 0) {
            shiftButton(direction: -1)
            Text(weekRange(days))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
            shiftButton(direction: 1)
        }
    }

    private func weekRange(_ days: [Date]) -> String {
        guard let first = days.first, let last = days.last else { return "This week" }
        let opens = first.formatted(.dateTime.month(.abbreviated).day())
        let closes = last.formatted(.dateTime.month(.abbreviated).day())
        return "\(opens) – \(closes)"
    }

    private func shiftButton(direction: Int) -> some View {
        Button {
            store.shiftSelection(by: direction)
        } label: {
            Image(systemName: direction < 0 ? "chevron.left" : "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(direction < 0 ? "Previous" : "Next")
    }

    private var progress: some View {
        let sessions = store.sessionsStarting(on: store.selectedDay)
        let total = max(sessions.reduce(0) { $0 + $1.durationMinutes }, 1)
        let done = store.completedMinutes(on: store.selectedDay)
        let planned = store.plannedMinutes(on: store.selectedDay)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("\(TimeText.minutes(done)) done")
                Text("·")
                Text("\(TimeText.minutes(planned)) planned")
                Spacer()
            }
            .font(.caption)
            .foregroundStyle(Theme.secondary)

            GeometryReader { geo in
                HStack(spacing: 2) {
                    if sessions.isEmpty {
                        Capsule().fill(Theme.line)
                    } else {
                        ForEach(sessions) { session in
                            let gaps = CGFloat(max(sessions.count - 1, 0)) * 2
                            let width = max(4, (geo.size.width - gaps) * CGFloat(session.durationMinutes) / CGFloat(total))
                            Capsule()
                                .fill(store.color(for: session).opacity(session.isComplete ? 1 : 0.38))
                                .frame(width: width)
                        }
                    }
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())
            .accessibilityLabel("\(TimeText.minutes(done)) done of \(TimeText.minutes(planned)) planned")
        }
    }

    private var weekStrip: some View {
        let calendar = Calendar.current
        return HStack(spacing: 4) {
            ForEach(store.daysInSelectedWeek(), id: \.self) { day in
                let selected = calendar.isDate(day, inSameDayAs: store.selectedDay)
                let sessions = store.sessionsStarting(on: day)
                Button {
                    store.selectedDay = day
                    if store.calendarMode == .month {
                        store.calendarMode = .day
                    }
                } label: {
                    VStack(spacing: 3) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2.weight(.semibold))
                        Text(day.formatted(.dateTime.day()))
                            .font(.subheadline.weight(.bold))
                        Circle()
                            .fill(dotColor(for: sessions))
                            .frame(width: 5, height: 5)
                            .opacity(sessions.isEmpty ? 0 : 1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        selected ? Theme.tatami : Color.clear,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .foregroundStyle(selected ? Color.white : Theme.ink)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private func dotColor(for sessions: [Session]) -> Color {
        if sessions.contains(where: { $0.needsMark() }) { return Theme.ember }
        if let first = sessions.first { return store.color(for: first) }
        return .clear
    }

    private var densityChips: some View {
        HStack(spacing: 8) {
            ForEach([60, 30, 15, 10], id: \.self) { minutes in
                let selected = store.slotMinutes == minutes
                Button("\(minutes)") {
                    store.updateSettings { $0.densityMinutes = minutes }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? Color.white : Theme.ink)
                .frame(minWidth: 44, minHeight: 36)
                .padding(.horizontal, 8)
                .background(selected ? Theme.tatami : Theme.elevated, in: Capsule())
                .buttonStyle(.plain)
                .accessibilityLabel("\(minutes) minute slots")
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }
    }

    private var addMenu: some View {
        Menu {
            Button("Add session", systemImage: "plus") {
                editor = .create(store.suggestedStart())
            }
            Button("Divide this hour", systemImage: "rectangle.split.3x1") {
                hourToDivide = HourStart(date: store.suggestedHour())
            }
            Button("Add a training week", systemImage: "calendar.badge.plus") {
                store.addTrainingPlan()
            }
        } label: {
            Image(systemName: "plus")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Theme.tatami, in: Circle())
        }
        .accessibilityLabel("Add")
    }
}
