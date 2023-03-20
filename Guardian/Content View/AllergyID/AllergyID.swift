//
//  AllergyID   .swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

struct AllergyID: View {
	var body: some View {
		VStack(spacing: 16.0) {

            Group {
                Text("食物アレルギーがあります")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 20.0)
                Text("こちらのアレルゲンは")
                    .padding(.horizontal, 20.0)
                Text("微量")
                    .font(.title2)
                    .bold()
                    .padding(.horizontal, 20.0)
                Text("でも食べられません")
                    .padding(.horizontal, 20.0)
                Text("えび、かに、そば、卵、乳成分")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 20.0)
                Text("ご理解の程、宜しくお願いいたします。")
                    .padding(.horizontal, 20.0)
            }
                
            Divider()
            Group {
                Text("緊急時には症状の回復の為")
                    .font(.headline)
                    .padding(.horizontal, 20.0)
                Text("ぜひ")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 20.0)
                Text("手伝ってください")
                    .font(.headline)
                    .padding(.horizontal, 20.0)
                Text("ーーーーーーーーーーーー")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20.0)
            }
			Button("📖 緊急対応マニュアル", action: {})
				.buttonStyle(.bordered)
		}
	}
}

struct AllergyID_Previews: PreviewProvider {
	static var previews: some View {
		AllergyID()
	}
}
