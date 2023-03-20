//
//  AllergenView.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

struct AllergenView: View {
	@State private var sliderValue: Float = 3
	@State private var textFieldInput: String = ""
	@State private var isActionSheetPresented = false
	
	var body: some View {
		ScrollView(.vertical) {
			LazyVStack(alignment: .leading, spacing: 16.0) {
                Group {
                    Text("クラス０:陰性 | クラス1:偽陽性 | クラス２～６:陽性")
                        .font(.subheadline)
                        .padding(.horizontal, 20.0)
                    Slider(value: $sliderValue, in: 0...6, step: 1) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("6")
                    }
                    .padding(.horizontal, 20.0)
                }
                Group {
                    Text("発症記録")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 20.0)
                    Text("医療機関での問診項目を用いた発症記録")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20.0)
                }
				Carousel()
				Button(action: {}) {
					Text("+新規記録を作成")
						.font(.title3)
						.bold()
				}
				.buttonStyle(FullWidthButtonStyle(cornerRadius: 28.0))
				Text("検査・診断結果の記録")
					.font(.title2)
					.bold()
					.padding(.horizontal, 20.0)
				Text("「血液検査、皮膚プリックテスト、食物経口負荷試験」結果を記録")
					.foregroundColor(.secondary)
					.padding(.horizontal, 20.0)
				Carousel2()
				Text("医師からのコメント")
					.font(.title2)
					.bold()
					.padding(.horizontal, 20.0)
				TextField("", text: $textFieldInput)
					.textFieldStyle(RoundedBorderTextFieldStyle())
					.padding(.horizontal, 20.0)
			}
		}
		.navigationTitle("アレルゲン名")
		.navigationDestination(for: AllergenViewCarouselItem.self) { item in
			DiaryView()
		}
		.navigationDestination(for: AllergenViewCarousel2Item.self) { item in
			ClinicalTestRecordView()
		}
		.actionSheet(isPresented: $isActionSheetPresented) {
			ActionSheet(title: Text("選択中のアレルゲンとデータを削除しまか？"), message: Text("実行しますか？"), buttons: [
				.destructive(Text("削除する")),
				.cancel(Text("キャンセル")),
			])
		}
	}
}

extension AllergenView {
	struct Carousel: View {
		@State var items = AllergenViewCarouselItem.data
		
		var body: some View {
			TabView {
				ForEach(items) { item in
					NavigationLink(value: item) {
						Card(headline: item.headline, caption: item.caption, image: Image(systemName: item.imageName))
							.padding(.horizontal, 20.0)
					}
					.buttonStyle(PlainButtonStyle())
				}
			}
			.tabViewStyle(PageTabViewStyle())
			.frame(height: 160.0)
		}
	}
}

extension AllergenView.Carousel {
	struct Card: View {
		let headline: String
		let caption: String
		let image: Image
		
		var body: some View {
			ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
				VStack(alignment: .leading, spacing: 8.0) {
					HStack(spacing: 16.0) {
						image
							.resizable()
							.frame(width: 24.0, height: 24.0)
							.padding(16.0)
							.background(Color.accentColor)
							.foregroundColor(.white)
							.clipShape(Circle())
						Text(headline)
							.font(.headline)
					}
					Text(caption)
						.font(.caption)
				}
				.padding(16.0)
				Color(.secondarySystemFill)
					.cornerRadius(10.0)
			}
		}
	}
}

extension AllergenView {
	struct Carousel2: View {
		@State var items = AllergenViewCarousel2Item.data
		
		var body: some View {
			TabView {
				ForEach(items) { item in
					NavigationLink(value: item) {
						Card(headline: item.headline, caption: item.caption, image: Image(systemName: item.imageName))
							.padding(.horizontal, 20.0)
					}
					.buttonStyle(PlainButtonStyle())
				}
			}
			.tabViewStyle(PageTabViewStyle())
			.frame(height: 160.0)
		}
	}
}

extension AllergenView.Carousel2 {
	struct Card: View {
		let headline: String
		let caption: String
		let image: Image
		
		var body: some View {
			ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
				VStack(alignment: .leading, spacing: 8.0) {
					HStack(spacing: 16.0) {
						image
							.resizable()
							.frame(width: 24.0, height: 24.0)
							.padding(16.0)
							.background(Color.accentColor)
							.foregroundColor(.white)
							.clipShape(Circle())
						Text(headline)
							.font(.headline)
					}
					Text(caption)
						.font(.caption)
				}
				.padding(16.0)
				Color(.secondarySystemFill)
					.cornerRadius(10.0)
			}
		}
	}
}

struct AllergenView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			AllergenView()
		}
	}
}
