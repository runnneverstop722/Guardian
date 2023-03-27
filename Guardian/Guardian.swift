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
                .tabItem { Label("カルテ", systemImage: "person.text.rectangle.fill") }
                IDcard()
                    .tabItem { Label("IDカード", systemImage: "menucard") }
                EmptyView()
                    .tabItem { Label("Fourth", systemImage: "wind") }
            }
        }
    }
}
