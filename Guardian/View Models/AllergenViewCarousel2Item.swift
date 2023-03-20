//
//  AllergenViewCarousel2Item.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

struct AllergenViewCarousel2Item: Identifiable, Hashable {
	let id = UUID()
	let headline: String
	let caption: String
	let imageName: String
}

extension AllergenViewCarousel2Item {
	static let data = [
		AllergenViewCarousel2Item(headline: "Lorem ipsum dolor", caption: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua", imageName: "sun.max"),
		AllergenViewCarousel2Item(headline: "Ut enim ad minim veniam", caption: "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat", imageName: "moon"),
		AllergenViewCarousel2Item(headline: "Duis aute irure dolor", caption: "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur", imageName: "umbrella"),
	]
}