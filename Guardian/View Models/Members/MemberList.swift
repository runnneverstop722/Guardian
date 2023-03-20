//
//  MemberList.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//
import SwiftUI
import PhotosUI
import CloudKit

struct MemberList: Identifiable, Hashable {
    
    let id = UUID()
    let headline: String
    let caption: String
    let imageName: String
}

extension MemberList {
    
    static let data = [
        MemberList(headline: "Lorem ipsum", caption: "Dolor sit amet", imageName: "Members.Item.0"),
        MemberList(headline: "Consectetur", caption: "Adipiscing elit", imageName: "Members.Item.1"),
        MemberList(headline: "Sed do eiusmod", caption: "Tempor incididunt ut labore", imageName: "Members.Item.2"),
        MemberList(headline: "Et dolore", caption: "Magna aliqua", imageName: "Members.Item.3"),
        MemberList(headline: "Ut enim", caption: "Ad minim veniam", imageName: "Members.Item.4"),
    ]
}
