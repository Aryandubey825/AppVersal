//
//  ContentView.swift
//  AppVersal
//

import SwiftUI
import Combine

struct ContentView: View {
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
        .tint(.accentColor)
    }
}

#Preview {
    ContentView()
}
