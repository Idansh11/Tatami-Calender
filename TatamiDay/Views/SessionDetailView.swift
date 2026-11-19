import SwiftUI

struct SessionDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let sessionID: UUID

    @State private var editor: EditorRoute?
    @State private var showDelete = false
    @State private var showDeleteScope = false

    var body: some View {
        NavigationStack {
            Group {
                if let session = session {
                    content(session)
                } else {
                    ContentUnavailableView("Session removed", systemImage: "calendar.badge.minus", description: Text("This block is no longer on the day."))
                        .onAppear { dismiss() }
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
        .sheet(item: $editor) { route in
            SessionEditorLoader(route: route)
                .presentationBackground(Theme.background)
        }
    }

    private var session: Session? {
        store.sessions.first { $0.id == sessionID }
    }

    private func content(_ session: Session) -> some View {
        let topic = store.topic(for: session)
        let color = store.color(for: session)
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Capsule()
                    .fill(color)
                    .frame(height: 8)
                    .accessibilityHidden(true)

                HStack(spacing: 8) {
                    SymbolIcon(name: topic?.symbol ?? "circle.fill")
                    Text(topic?.name ?? "Topic")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(minHeight: 36)
                .background(color.opacity(0.16), in: Capsule())
                .foregroundStyle(color)

                Text(session.title)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.ink)
                    .strikethrough(session.isComplete, color: Theme.secondary)

                Text(detailWhen(session))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)

                Text(TimeText.minutes(session.durationMinutes))
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)

                if session.needsMark() {
                    Text("This stays open until you mark it done.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ember)
                } else if session.isLive() {
                    Text("Happening now.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.gold)
                }

                if !session.place.isEmpty {
                    Label(session.place, systemImage: "mappin.and.ellipse")
                        .font(.body)
                        .foregroundStyle(Theme.ink)
                }
                if !session.notes.isEmpty {
                    Text(session.notes)
                        .font(.body)
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if session.requiresCompletion {
                    Button(session.isComplete ? "Mark not done" : "Mark done") {
                        store.setComplete(session.id, complete: !session.isComplete)
                    }
                    .buttonStyle(TatamiButtonStyle())
                    .sensoryFeedback(.success, trigger: session.isComplete)
                }

                Button("Edit") { editor = .edit(session.id) }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .background(Theme.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button("Delete", role: .destructive) {
                    if session.seriesID == nil {
                        showDelete = true
                    } else {
                        showDeleteScope = true
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .confirmationDialog("Delete this session?", isPresented: $showDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.delete(sessionID: session.id, scope: .one)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete the series?", isPresented: $showDeleteScope, titleVisibility: .visible) {
            Button("Only this session", role: .destructive) {
                store.delete(sessionID: session.id, scope: .one)
                dismiss()
            }
            Button("This and following", role: .destructive) {
                store.delete(sessionID: session.id, scope: .following)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func detailWhen(_ session: Session) -> String {
        let day = session.start.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
        return "\(day) · \(TimeText.range(start: session.start, end: session.end))"
    }
}
