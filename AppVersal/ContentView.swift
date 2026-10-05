import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "calendar")
                }
                .tag(1)

            TrashView()
                .tabItem {
                    Label("Trash", systemImage: "trash.fill")
                }
                .tag(2)
        }
        .tint(.blue)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                PhotoLibraryService.shared.notifyLibraryChanged()
            }
        }
    }
}

#Preview {
    ContentView()
}
