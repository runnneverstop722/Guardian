//
//  ExportDiaryClinicalRecordsItem.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

struct ExportDiaryClinicalRecordsItem: Identifiable {
	let id = UUID()
	let headline: String
	let caption: String
	let imageName: String
}

extension ExportDiaryClinicalRecordsItem {
	static let data = [
		ExportDiaryClinicalRecordsItem(headline: "Lorem ipsum", caption: "Dolor sit amet", imageName: "gyroscope"),
		ExportDiaryClinicalRecordsItem(headline: "Consectetur", caption: "Adipiscing elit", imageName: "house"),
		ExportDiaryClinicalRecordsItem(headline: "Sed do eiusmod", caption: "Tempor incididunt ut labore", imageName: "sun.max"),
		ExportDiaryClinicalRecordsItem(headline: "Et dolore", caption: "Magna aliqua", imageName: "moon"),
		ExportDiaryClinicalRecordsItem(headline: "Ut enim", caption: "Ad minim veniam", imageName: "umbrella"),
	]
}