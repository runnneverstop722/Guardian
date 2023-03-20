//
//  ClinicalTestRecordView.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI

struct ClinicalTestRecordView: View {
    @State private var sliderValue: Float = 3
    @State private var textFieldInput: String = ""
    @State private var textField2Input: String = ""
    @State private var textField3Input: String = ""
    @State private var textField4Input: String = ""
    @State private var textField5Input: String = ""
    @State private var textField6Input: String = ""
    @State private var showYes = true
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 16.0) {
                Group {
                    Text("血液検査")
                        .font(.title)
                        .bold()
                        .padding(.horizontal, 20.0)
                    Text("記録1")
                        .padding(.horizontal, 20.0)
                    Text("日付")
                        .font(.subheadline)
                        .padding(.horizontal, 20.0)
                    TextField("", text: $textFieldInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                    Text("「IgE抗体」測定値")
                        .font(.subheadline)
                        .padding(.horizontal, 20.0)
                    TextField("", text: $textField2Input)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                    Text("「IgE抗体」クラス")
                        .font(.subheadline)
                        .padding(.horizontal, 20.0)
                    Slider(value: $sliderValue, in: 0...6, step: 0.5) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("6")
                    }
                    .padding(.horizontal, 20.0)
                    Text("クラスは0-6の7段階で表記されており、クラス0が陰性、クラス1が偽陽性、クラス2-6が陽性と判断されます。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20.0)
                    Button(action: {}) {
                        Text("+新規記録を作成")
                            .font(.title3)
                            .bold()
                    }
                    .buttonStyle(FullWidthButtonStyle(cornerRadius: 28.0))
                }
                Group {
                    Text("皮膚プリック/スクラッチテスト")
                        .font(.title)
                        .bold()
                        .padding(.horizontal, 20.0)
                    Text("記録1")
                        .padding(.horizontal, 20.0)
                    Text("日付")
                        .font(.subheadline)
                        .padding(.horizontal, 20.0)
                    TextField("", text: $textField3Input)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                    Text("結果(mm)")
                        .font(.subheadline)
                        .padding(.horizontal, 20.0)
                    TextField("", text: $textField4Input)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                    Text("判定")
                        .font(.subheadline)
                        .padding(.horizontal, 20.0)
                    TextField("陰性(-)/陽生(+)", text: $textField5Input)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                    Button(action: {}) {
                        Text("+新規記録を作成")
                            .font(.title3)
                            .bold()
                    }
                    .buttonStyle(FullWidthButtonStyle(cornerRadius: 28.0))
                }
                Group {
                    Text("食物経口負荷試験")
                        .font(.title)
                        .bold()
                        .padding(.horizontal, 20.0)
                    Text("記録1")
                        .padding(.horizontal, 20.0)
                    Text("日付")
                        .padding(.horizontal, 20.0)
                    TextField("", text: $textField6Input)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                    Text("試した量")
                        .font(.subheadline)
                        .padding(.horizontal, 20.0)
                    TextField("", text: $textField4Input)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20.0)
                    Text("発症の有無")
                        .font(.subheadline)
                        .padding(.horizontal, 20.0)
                    HStack {
                        Toggle("", isOn: $showYes)
                    }
                    .padding(.horizontal, 20.0)
                    Button(action: {}) {
                        Text("+新規記録を作成")
                            .font(.title3)
                            .bold()
                    }
                    .buttonStyle(FullWidthButtonStyle(cornerRadius: 28.0))
                }
            }
        }
        .navigationTitle("検査・診断結果の記録")
    }
}

struct ClinicalTestRecordView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ClinicalTestRecordView()
        }
    }
}
