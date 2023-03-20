//
//  ExportDiaryClinicalRecords.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

struct ExportDiaryClinicalRecords: View {
	@State var items = ExportDiaryClinicalRecordsItem.data
	
	var body: some View {
		List(items) { item in
			Row(headline: item.headline, caption: item.caption, image: Image(systemName: item.imageName))
		}
		.listStyle(.plain)
	}
}

extension ExportDiaryClinicalRecords {
	struct Row: View {
		let headline: String
		let caption: String
		let image: Image
		
		var body: some View {
			HStack(spacing: 16.0) {
				image
					.resizable()
					.frame(width: 24.0, height: 24.0)
					.padding(16.0)
					.background(Color.accentColor)
					.foregroundColor(.white)
					.clipShape(RoundedRectangle(cornerRadius: 8.0))
				VStack(alignment: .leading, spacing: 4.0) {
					Text(headline)
						.font(.headline)
					Text(caption)
						.font(.subheadline)
						.foregroundColor(.secondary)
				}
			}
		}
	}
}

struct ExportDiaryClinicalRecords_Previews: PreviewProvider {
	static var previews: some View {
		ExportDiaryClinicalRecords()
	}
}