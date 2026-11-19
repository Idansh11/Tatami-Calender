import SwiftUI

struct DivideHourSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let hour: Date

    @State private var parts = 4
    @State private var topicID = TopicID.judo
    @State private var titles = Array(repeating: "", count: 6)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(hour.formatted(.dateTime.weekday(.wide).hour().minute()))
                        .font(.headline)
                    Picker("Split", selection: $parts) {
                        Text("2 × 30 min").tag(2)
                        Text("3 × 20 min").tag(3)
                        Text("4 × 15 min").tag(4)
                        Text("6 × 10 min").tag(6)
                    }
                    Text("\(parts) blocks, \(60 / parts) minutes each. Existing sessions stay where they are.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondary)
                }

                Section("Topic") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.topicsForPicker()) { topic in
                                let selected = topicID == topic.id
                                Button {
                                    topicID = topic.id
                                } label: {
                                    Text(topic.name)
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

                Section("Blocks") {
                    ForEach(0..<parts, id: \.self) { index in
                        TextField(placeholder(index), text: titleBinding(index))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Divide the hour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func placeholder(_ index: Int) -> String {
        let start = hour.addingTimeInterval(TimeInterval(index * (60 / parts) * 60))
        return start.formatted(date: .omitted, time: .shortened)
    }

    private func titleBinding(_ index: Int) -> Binding<String> {
        Binding(
            get: { titles.indices.contains(index) ? titles[index] : "" },
            set: { newValue in
                guard titles.indices.contains(index) else { return }
                titles[index] = newValue
            }
        )
    }

    private func save() {
        store.divideHour(start: hour, parts: parts, topicID: topicID, titles: titles)
        dismiss()
    }
}
