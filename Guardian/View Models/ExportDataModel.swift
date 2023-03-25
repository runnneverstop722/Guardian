//
//  ExportDataModel.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

struct ExportDataModel: Identifiable {
    let id = UUID()
    let headline: String
    let caption: String
    let imageName: String
}

extension ExportDataModel {
    static let data = [
        ExportDataModel(headline: "Lorem ipsum", caption: "Dolor sit amet", imageName: "gyroscope"),
        ExportDataModel(headline: "Consectetur", caption: "Adipiscing elit", imageName: "house"),
        ExportDataModel(headline: "Sed do eiusmod", caption: "Tempor incididunt ut labore", imageName: "sun.max"),
        ExportDataModel(headline: "Et dolore", caption: "Magna aliqua", imageName: "moon"),
        ExportDataModel(headline: "Ut enim", caption: "Ad minim veniam", imageName: "umbrella"),
    ]
}
