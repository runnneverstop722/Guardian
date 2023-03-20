//
//  LandingPage.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

struct LandingPage: View {
	var body: some View {
		VStack(spacing: 16.0) {
			Image("logo")
				.resizable()
                .aspectRatio(contentMode: .fit)
			
			ProgressView("Loading...")
				.padding(.horizontal, 20.0)
			Text("監修：〜〜先生~~病院 ~~専門")
				.bold()
				.foregroundColor(.secondary)
				.padding(.horizontal, 20.0)
		}
	}
}

struct LandingPage_Previews: PreviewProvider {
	static var previews: some View {
		LandingPage()
	}
}
