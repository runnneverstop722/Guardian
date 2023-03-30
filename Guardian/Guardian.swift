//
//  Guardian.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI
import CloudKit

@main
struct Guardian: App {

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    MembersView()
                }
                .tabItem { Label("管理メンバー", systemImage: "person.text.rectangle.fill") }
                Awareness()
                    .tabItem { Label("周知", systemImage: "exclamationmark.bubble") }
                EmptyView()
                    .tabItem { Label("Fourth", systemImage: "wind") }
            }
        }
    }
}
