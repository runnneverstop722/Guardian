//
//  Guardian.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI
import CloudKit
import CoreData

@main
struct Guardian: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    MembersView()
                }
                .tabItem { Label("管理メンバー", systemImage: "person.text.rectangle.fill") }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)

                AwarenessView()
                    .tabItem { Label("周知", systemImage: "exclamationmark.bubble") }
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)

                EmptyView()
                    .tabItem { Label("Fourth", systemImage: "wind") }
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
