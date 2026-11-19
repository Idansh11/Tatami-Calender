import SwiftUI

struct TopicsView: View {
    @Environment(AppStore.self) private var store
    @State private var filter: String?
    @State private var editor: TopicDraft?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    Section {
                        Text("Topics color the calendar. Judo, running, walking, lifting, recovery, and the rest of a training day are already here. Add your own.")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondary)
                            .listRowBackground(Color.clear)
                    }
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                filterChip("All", value: nil)
                                ForEach(TopicGroup.order, id: \.self) { group in
                                    filterChip(group, value: group)
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                    ForEach(store.groupedTopics(filter: filter), id: \.0) { pair in
                        Section(pair.0) {
                            ForEach(pair.1) { topic in
                                Button {
                                    editor = .edit(topic)
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle().fill(Color(hex: topic.colorHex))
                                            SymbolIcon(name: topic.symbol)
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(Contrast.ink(on: topic.colorHex))
                                        }
                                        .frame(width: 36, height: 36)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(topic.name)
                                                .font(.body.weight(.semibold))
                                                .foregroundStyle(Theme.ink)
                                            if !topic.titleIdeas.isEmpty {
                                                Text(topic.titleIdeas.prefix(3).joined(separator: ", "))
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        Spacer()
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color(hex: topic.colorHex))
                                            .frame(width: 18, height: 18)
                                    }
                                    .frame(minHeight: 44)
                                }
                                .listRowBackground(Theme.surface)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Topics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editor = .create()
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("New topic")
                }
            }
            .sheet(item: $editor) { draft in
                TopicEditorView(draft: draft)
                    .presentationBackground(Theme.background)
            }
        }
    }

    private func filterChip(_ title: String, value: String?) -> some View {
        let selected = filter == value
        return Button(title) { filter = value }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(selected ? Color.white : Theme.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: 34)
            .background(selected ? Theme.tatami : Theme.elevated, in: Capsule())
            .buttonStyle(.plain)
            .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct TopicDraft: Identifiable, Equatable {
    var id: UUID
    var topicID: UUID?
    var name: String
    var symbol: String
    var colorHex: String
    var group: String
    var ideasText: String
    var isPreset: Bool

    var ideas: [String] {
        ideasText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func create() -> TopicDraft {
        TopicDraft(
            id: UUID(),
            topicID: nil,
            name: "",
            symbol: "figure.run",
            colorHex: "2F8F62",
            group: "Custom",
            ideasText: "",
            isPreset: false
        )
    }

    static func edit(_ topic: Topic) -> TopicDraft {
        TopicDraft(
            id: topic.id,
            topicID: topic.id,
            name: topic.name,
            symbol: topic.symbol,
            colorHex: topic.colorHex,
            group: topic.group,
            ideasText: topic.titleIdeas.joined(separator: ", "),
            isPreset: topic.isPreset
        )
    }
}

struct TopicEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: TopicDraft
    @State private var localError: String?

    init(draft: TopicDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Topic") {
                    TextField("Name", text: $draft.name)
                    Picker("Group", selection: $draft.group) {
                        ForEach(TopicGroup.order, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                    TextField("Title ideas, separated by commas", text: $draft.ideasText, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section("Symbol") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(SymbolChoices.all, id: \.self) { symbol in
                            Button {
                                draft.symbol = symbol
                            } label: {
                                SymbolIcon(name: symbol)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        draft.symbol == symbol ? Color(hex: draft.colorHex) : Theme.elevated,
                                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    )
                                    .foregroundStyle(draft.symbol == symbol ? Contrast.ink(on: draft.colorHex) : Theme.ink)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(symbol)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Color") {
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
                        }
                    }
                    ColorPicker("Custom color", selection: colorBinding, supportsOpacity: false)
                }
                if draft.isPreset {
                    Section {
                        Button("Restore original") {
                            if let id = draft.topicID {
                                store.restorePreset(id)
                                dismiss()
                            }
                        }
                    } footer: {
                        Text("Built-in topics stay in the library. Color, name, and symbol can still change.")
                    }
                } else if draft.topicID != nil {
                    Section {
                        Button("Delete topic", role: .destructive) {
                            guard let id = draft.topicID else { return }
                            store.deleteTopic(id)
                            if store.topic(for: id) == nil {
                                dismiss()
                            } else {
                                localError = store.alertMessage ?? "That topic could not be deleted."
                                store.alertMessage = nil
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(draft.topicID == nil ? "New topic" : "Edit topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .alert(
                "Tatami Day",
                isPresented: Binding(
                    get: { localError != nil },
                    set: { if !$0 { localError = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(localError ?? "")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: draft.colorHex) },
            set: { draft.colorHex = $0.hexRGB() }
        )
    }

    private func save() {
        let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            localError = "Give the topic a name."
            return
        }
        if let id = draft.topicID, var topic = store.topic(for: id) {
            topic.name = trimmed
            topic.symbol = draft.symbol
            topic.colorHex = draft.colorHex
            topic.group = draft.group
            topic.titleIdeas = draft.ideas
            store.updateTopic(topic)
        } else {
            store.addTopic(
                name: trimmed,
                symbol: draft.symbol,
                hex: draft.colorHex,
                group: draft.group,
                ideas: draft.ideas
            )
        }
        dismiss()
    }
}
