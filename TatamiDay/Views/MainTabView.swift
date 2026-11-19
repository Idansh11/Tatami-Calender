import SwiftUI

struct MainTabView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            CalendarShellView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .badge(store.overdueCount)

            TopicsView()
                .tabItem { Label("Topics", systemImage: "tag") }

            AthleteHomeView()
                .tabItem { Label("Athlete", systemImage: "figure.run") }
        }
        .toolbarBackground(Theme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .sheet(item: inspectBinding) { link in
            SessionDetailView(sessionID: link.id)
        }
        .sheet(isPresented: overdueBinding) {
            OverdueSheet()
                .presentationBackground(Theme.background)
        }
        .sheet(isPresented: onboardingBinding) {
            OnboardingView()
                .interactiveDismissDisabled()
                .presentationBackground(Theme.background)
        }
        .onAppear {
            refreshLiveServices()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refreshLiveServices()
        }
        .onChange(of: store.settings.didFinishOnboarding) { _, finished in
            if finished { store.presentOverdueIfNeeded() }
        }
    }

    private var inspectBinding: Binding<SessionLink?> {
        Binding(
            get: { store.inspectedSessionID.map(SessionLink.init) },
            set: { store.inspectedSessionID = $0?.id }
        )
    }

    private var overdueBinding: Binding<Bool> {
        Binding(
            get: { store.showOverdueSheet },
            set: { store.showOverdueSheet = $0 }
        )
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { store.phase == .ready && !store.settings.didFinishOnboarding },
            set: { _ in }
        )
    }

    private func refreshLiveServices() {
        guard store.runsLiveServices else { return }
        Task { await NotificationScheduler.resync(store) }
        store.presentOverdueIfNeeded()
    }
}

#Preview("Calendar") {
    MainTabView()
        .environment(AppStore(preview: true))
}
