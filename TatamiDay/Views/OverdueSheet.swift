import SwiftUI

struct OverdueSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.overdueSessions().isEmpty {
                    ContentUnavailableView(
                        "Day closed",
                        systemImage: "checkmark.circle",
                        description: Text("Every finished session is marked done.")
                    )
                } else {
                    List {
                        Section {
                            Text("Each one stays open until you mark it done.")
                                .font(.footnote)
                                .foregroundStyle(Theme.secondary)
                                .listRowBackground(Theme.surface)
                        }
                        ForEach(store.overdueSessions()) { session in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(store.color(for: session))
                                        .frame(width: 4, height: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(session.title)
                                            .font(.headline)
                                            .foregroundStyle(Theme.ink)
                                        Text(store.topic(for: session)?.name ?? "Session")
                                            .font(.caption)
                                            .foregroundStyle(Theme.secondary)
                                        Text(TimeText.range(start: session.start, end: session.end))
                                            .font(.caption)
                                            .foregroundStyle(Theme.secondary)
                                    }
                                }
                                Button("Mark done") {
                                    store.setComplete(session.id, complete: true)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.tatami)
                                .sensoryFeedback(.success, trigger: session.isComplete)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Theme.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background)
            .navigationTitle("Mark done")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
