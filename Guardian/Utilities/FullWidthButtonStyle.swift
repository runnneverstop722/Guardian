//
//  FullWidthButtonStyle.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

struct FullWidthButtonStyle: ButtonStyle {
	var cornerRadius: CGFloat
	
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.padding(.vertical, 16.0)
			.frame(maxWidth: .infinity)
			.foregroundColor(.white)
			.background(
				Color.accentColor
					.opacity(configuration.isPressed ? 0.3 : 1.0))
			.cornerRadius(cornerRadius)
			.padding(.horizontal, 20.0)
	}
}