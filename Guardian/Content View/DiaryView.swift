//
//  DiaryView.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

struct DiaryView: View {
	@State private var textFieldInput: String = ""
	@State private var textField2Input: String = ""
	@State private var textField3Input: String = ""
	@State private var textField4Input: String = ""
	@State private var textField5Input: String = ""
	@State private var textField6Input: String = ""
	@State private var textField7Input: String = ""
	
	var body: some View {
		ScrollView(.vertical) {
			LazyVStack(alignment: .leading, spacing: 16.0) {
                Button(action: {}) {
                    Text("+追加")
                        .font(.title3)
                        .bold()
                }
                .buttonStyle(FullWidthButtonStyle(cornerRadius: 28.0))
                Group {
                    Text("日付")
                        .padding(.horizontal, 20.0)
                    TextField("", text: $textFieldInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                    Text("初発症")
                        .padding(.horizontal, 20.0)
                    Button("Toggle", action: {})
                        .buttonStyle(.borderedProminent)
                    Text("外来受診済み")
                        .padding(.horizontal, 20.0)
                    Button("Toggle", action: {})
                        .buttonStyle(.borderedProminent)
                }
                Group {
                    Text("どのようにアレルゲンに触れたか")
                        .font(.title3)
                        .bold()
                        .padding(.horizontal, 20.0)
                    TextField("✅食べた/✅皮膚に接触/✅におい/✅不明", text: $textField2Input)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                    Text("どのような症状が現れたか")
                        .font(.title3)
                        .bold()
                        .padding(.horizontal, 20.0)
                    TextField("目(目のかゆみ/充血/まぶたの腫れ)/鼻(くしゃみ/鼻水/鼻づまり)/口(口の中の違和感/唇の腫れ)/呼吸器(咳/喘鳴（呼吸時にぜいぜいと雑音を発すること）/声枯れ/呼吸困難)/皮ふ(かゆみ/じんましん/赤くなる/むくみ/湿疹)/消化器(腹痛/吐き気/下痢/嘔吐)/ショック(意識がない/ぐったり/唇や爪が青白い)/神経(頭痛/活気の低下/意識障害),循環器(不整脈,頻脈(心拍数が増加している状態))", text: $textField3Input)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                    TextField("その他の症状", text: $textField4Input)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                    Text("症状が現れたのはアレルゲンに触れてからどれくらい経ってからか")
                        .font(.title3)
                        .bold()
                        .padding(.horizontal, 20.0)
                    TextField("5分未満/5~10min/10~15min/15~30min/30~60min/60min~", text: $textField5Input)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                }
                Group {
                    Text("どのような対応が取られたか")
                        .font(.title3)
                        .bold()
                        .padding(.horizontal, 20.0)
                    TextField("薬の服用/エピペンの注入/", text: $textField6Input)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                    TextField("その他の対応", text: $textField7Input)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                }
			}
		}
		.navigationTitle("□□発症記録")
	}
}

struct DiaryView_Previews: PreviewProvider {
	static var previews: some View {
		NavigationStack {
			DiaryView()
		}
	}
}
