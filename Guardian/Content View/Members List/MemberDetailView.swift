//
//  MemberDetailView.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI
import Foundation
import PhotosUI

struct MemberDetailView: View {
	@State private var isActionSheetPresented = false
	
	var body: some View {
		ScrollView(.vertical) {
			LazyVStack(alignment: .leading, spacing: 16.0) {
				Button(action: {}) {
					Text("+アレルゲンを追加")
						.font(.title3)
						.bold()
				}
				.buttonStyle(FullWidthButtonStyle(cornerRadius: 28.0))
				Text("登録済みアレルゲン")
					.font(.title3)
					.bold()
					.padding(.horizontal, 20.0)
				Grid()
			}
		}
		.navigationTitle("メンバー名")
        
		.navigationDestination(for: MemberDetailViewGridItem.self) { item in
			AllergenView()
		}
		.actionSheet(isPresented: $isActionSheetPresented) {
			ActionSheet(title: Text("データをエクスポート"), message: Text("記録済みの全データをPDFファイルに保存します"), buttons: [
				.default(Text("ファイルに保存する")),
				.cancel(Text("キャンセル")),
			])
		}
	}
}

extension MemberDetailView {
	struct Grid: View {
		@State var items = MemberDetailViewGridItem.data
		private let columns = Array(
			repeating: GridItem(.flexible(maximum: maxWidth), spacing: horizontalSpacing),
			count: columnCount)
		
		var body: some View {
			LazyVGrid(columns: columns, spacing: Self.verticalSpacing) {
				ForEach(items) { item in
					NavigationLink(value: item) {
						Cell(headline: item.headline, caption: item.caption, image: Image(systemName: item.imageName))
					}
					.buttonStyle(PlainButtonStyle())
				}
			}
		}
	}
}

private extension MemberDetailView.Grid {
	static let horizontalSpacing: CGFloat = 16.0
	static let verticalSpacing: CGFloat = 16.0
	static let horizontalInsets: CGFloat = 20.0
	static let columnCount = 2
	
	static var maxWidth: CGFloat {
		let spacing: CGFloat = CGFloat(columnCount - 1) * horizontalSpacing + horizontalInsets * 2
		return (UIScreen.main.bounds.width - spacing) / CGFloat(columnCount)
	}
}

extension MemberDetailView.Grid {
	struct Cell: View {
		let headline: String
		let caption: String
		let image: Image
		
		var body: some View {
			ZStack(alignment: Alignment(horizontal: .center, vertical: .top)) {
				VStack(alignment: .center, spacing: 8.0) {
					image
						.resizable()
						.frame(width: 24.0, height: 24.0)
						.padding(16.0)
						.background(Color.accentColor)
						.foregroundColor(.white)
						.clipShape(Circle())
					Text(headline)
						.font(.headline)
					Text(caption)
						.font(.caption)
				}
				.multilineTextAlignment(.center)
				.padding(16.0)
				Color(.secondarySystemFill)
					.cornerRadius(10.0)
			}
		}
	}
}

struct MemberDetailView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			MemberDetailView()
		}
	}
}
