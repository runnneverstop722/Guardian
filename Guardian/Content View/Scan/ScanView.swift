//
//  ScanView.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

struct ScanView: View {
	var body: some View {
		Text("スキャンしたい箇所が黄色の枠に囲まれたら、右側に現れたアイコンをタップしてください。読み取れたアレルゲンが画面下部に表示されます。")
			.padding(.horizontal, 20.0)
	}
}

struct ScanView_Previews: PreviewProvider {
	static var previews: some View {
		ScanView()
	}
}