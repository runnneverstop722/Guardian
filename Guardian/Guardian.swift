//
//  TabbedApp.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

@main
struct Guardian: App {
	var body: some Scene {
		WindowGroup {
			TabView {
				NavigationStack {
					Members()
				}
				.tabItem { Label("メンバー", systemImage: "person.3") }
				ScanView()
					.tabItem { Label("スキャン", systemImage: "doc.viewfinder") }
				AllergyID()
					.tabItem { Label("IDカード", systemImage: "menucard") }
				EmptyView()
					.tabItem { Label("Fourth", systemImage: "wind") }
			}
		}
	}
}
