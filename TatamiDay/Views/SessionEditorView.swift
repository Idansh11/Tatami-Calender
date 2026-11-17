import SwiftUI

struct SessionEditorLoader: View {
    @Environment(AppStore.self) private var store
    let route: EditorRoute

    var body: some View {
        SessionEditorView(draft: store.makeDraft(for: route))
    }
}

struct SessionEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: SessionDraft
    @State private var showSaveScope = false
    @State private var showDeleteScope = false
    @State private var showDeleteConfirm = false

    init(draft: SessionDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    TextField("Title", text: $draft.title)
                    topicPicker
                    if let ideas = store.topic(for: draft.topicID)?.titleIdeas, !ideas.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ideas, id: \.self) { idea in
                                    Button(idea) { draft.title = idea }
                                        .font(.footnote.weight(.semibold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Theme.elevated, in: Capsule())
                                        .foregroundStyle(Theme.ink)
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                }

                Section("When") {
                    DatePicker("Starts", selection: $draft.start)
                    Stepper(value: $draft.durationMinutes, in: 5...360, step: 5) {
                        Text("Duration \(TimeText.minutes(draft.durationMinutes))")
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([15, 20, 30, 45, 60, 75, 90, 120], id: \.self) { minutes in
                                Button(TimeText.minutes(minutes)) {
                                    draft.durationMinutes = minutes
                                }
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(draft.durationMinutes == minutes ? Theme.tatami : Theme.elevated, in: Capsule())
                                .foregroundStyle(draft.durationMinutes == minutes ? Color.white : Theme.ink)
                            }
                        }
                    }
                    Text(endText)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondary)
                    if draft.isNew {
                        Picker("Repeat", selection: $draft.repeatRule) {
                            ForEach(RepeatRule.allCases) { rule in
                                Text(rule.title).tag(rule)
                            }
                        }
                        if draft.repeatRule != .never {
                            Text("Repeats for 8 weeks from this start. You can later change one session or the rest of the series.")
                                .font(.footnote)
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                }

                Section("Place and notes") {
                    TextField("Place", text: $draft.place)
                    TextField("Notes", text: $draft.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Color") {
                    Toggle("Custom color", isOn: $draft.useCustomColor)
                    if draft.useCustomColor {
                        colorChoices
                        ColorPicker("Color", selection: colorBinding, supportsOpacity: false)
                    } else if let topic = store.topic(for: draft.topicID) {
                        Label(topic.name, systemImage: topic.symbol)
                            .foregroundStyle(Color(hex: topic.colorHex))
                    }
                }

                Section {
                    Toggle("Remind me", isOn: $draft.wantsReminder)
                    if draft.wantsReminder {
                        Picker("Before it starts", selection: $draft.leadMinutes) {
                            Text("5 min").tag(5)
                            Text("10 min").tag(10)
                            Text("15 min").tag(15)
                            Text("30 min").tag(30)
                            Text("1 hour").tag(60)
                        }
                    }
                    Toggle("Require mark as done", isOn: $draft.requiresCompletion)
                } footer: {
                    Text("If this stays on, Tatami Day keeps the session open and notifies you until you mark it done.")
                }

                if !draft.isNew {
                    Section {
                        Button("Delete session", role: .destructive) {
                            if draft.seriesID == nil {
                                showDeleteConfirm = true
                            } else {
                                showDeleteScope = true
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(draft.isNew ? "New session" : "Edit session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { attemptSave() }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: draft.topicID) { previous, current in
                applyTopicChange(from: previous, to: current)
            }
            .confirmationDialog("Update the series?", isPresented: $showSaveScope, titleVisibility: .visible) {
                Button("Only this session") { save(scope: .one) }
                Button("This and following") { save(scope: .following) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This and following keeps each date and updates the time, topic, and details.")
            }
            .confirmationDialog("Delete the series?", isPresented: $showDeleteScope, titleVisibility: .visible) {
                Button("Only this session", role: .destructive) { delete(scope: .one) }
                Button("This and following", role: .destructive) { delete(scope: .following) }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Delete this session?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { delete(scope: .one) }
                Button("Cancel", role: .cancel) {}
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var topicPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.topicsForPicker()) { topic in
                    let selected = draft.topicID == topic.id
                    Button {
                        draft.topicID = topic.id
                    } label: {
                        HStack(spacing: 6) {
                            SymbolIcon(name: topic.symbol)
                            Text(topic.name)
                        }
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .frame(minHeight: 36)
                        .background(selected ? Color(hex: topic.colorHex) : Theme.elevated, in: Capsule())
                        .foregroundStyle(selected ? Contrast.ink(on: topic.colorHex) : Theme.ink)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var colorChoices: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
            ForEach(Swatches.all, id: \.self) { hex in
                Button {
                    draft.colorHex = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if draft.colorHex.uppercased() == hex {
                                Image(systemName: "checkmark")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(Contrast.ink(on: hex))
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Color \(hex)")
            }
        }
        .padding(.vertical, 4)
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: draft.colorHex) },
            set: { draft.colorHex = $0.hexRGB() }
        )
    }

    private var endText: String {
        let end = draft.end
        let time = end.formatted(date: .omitted, time: .shortened)
        if Calendar.current.isDate(draft.start, inSameDayAs: end) {
            return "Ends \(time)"
        }
        return "Ends \(time), next day"
    }

    private func applyTopicChange(from previous: UUID, to current: UUID) {
        let oldTopic = store.topic(for: previous)
        let newTopic = store.topic(for: current)
        let trimmed = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let automatic = trimmed.isEmpty || trimmed == oldTopic?.name || (oldTopic?.titleIdeas.contains(trimmed) ?? false)
        if automatic, let name = newTopic?.name {
            draft.title = name
        }
        if !draft.useCustomColor, let hex = newTopic?.colorHex {
            draft.colorHex = hex
        }
    }

    private func attemptSave() {
        if !draft.isNew, draft.seriesID != nil {
            showSaveScope = true
        } else {
            save(scope: .one)
        }
    }

    private func save(scope: SeriesScope) {
        if draft.isNew {
            store.saveNew(draft: draft)
        } else {
            store.saveExisting(draft: draft, scope: scope)
        }
        dismiss()
    }

    private func delete(scope: SeriesScope) {
        store.delete(sessionID: draft.id, scope: scope)
        dismiss()
    }
}
