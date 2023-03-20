//
//  MemberDetailViewGridItem.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

struct MemberDetailViewGridItem: Identifiable, Hashable {
	let id = UUID()
	let headline: String
	let caption: String
	let imageName: String
}

extension MemberDetailViewGridItem {
	static let data: [MemberDetailViewGridItem] = {
		var data: [MemberDetailViewGridItem] = []
		for _ in 0 ..< 8 {
			let item = MemberDetailViewGridItem(headline: "Lorem", caption: "Lorem ipsum dolor sit amet", imageName: "gyroscope")
			data.append(item)
		}
		return data
	}()
}