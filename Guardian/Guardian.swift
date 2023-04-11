//
//  Guardian.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI
import CloudKit

class AppState: ObservableObject {
    @Published var isAwarenessTabDisabled = true
}

struct NoticeView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("アップデート予定")
                .font(.largeTitle)
                .bold()
            Text("(外食時)食物アレルギーお知らせ")
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
            Text("Coming in May'23")
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
        .foregroundColor(.white)
        .mask(LinearGradient(gradient: Gradient(stops: [
            Gradient.Stop(color: Color.clear, location: 0),
            Gradient.Stop(color: Color.white, location: 0.1),
            Gradient.Stop(color: Color.white, location: 0.9),
            Gradient.Stop(color: Color.clear, location: 1)
        ]), startPoint: .top, endPoint: .bottom))
    }
}

@main
struct Guardian: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    MembersView()
                }
                .tabItem { Label("管理メンバー", systemImage: "person.text.rectangle.fill") }

                Awareness()
                    .environmentObject(appState)
                    .tabItem { Label("周知", systemImage: "exclamationmark.bubble") }

                EmptyView()
                    .tabItem { Label("Fourth", systemImage: "wind") }
            }
        }
    }
}
