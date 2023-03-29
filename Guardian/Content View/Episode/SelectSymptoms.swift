//
//  SelectSymptoms.swift
//  Guardian
//
//  Created by Teff on 2023/03/22.
//
import SwiftUI

struct SelectSymptoms: View {
    let category: String
    @Binding var selectedSymptoms: [String]

    let symptoms: [String]

    init(category: String, selectedSymptoms: Binding<[String]>) {
        self.category = category
        self._selectedSymptoms = selectedSymptoms

        switch category {
        case "皮膚":
            symptoms = ["かぶれ", "じんましん", "かゆみ", "紅潮/赤み", "しゃく熱感", "湿疹", "むくみ/浮腫/血管性浮腫"]
        case "呼吸器":
            symptoms = ["間欠的な咳", "鼻閉（鼻つまり）", "くしゃみ", "断統的な咳", "持続する強い咳き込み", "犬吠様咳嗽（犬が吠えたような鳴き声の咳）", "聴診上の喘鳴", "軽い息苦しさ", "明らかな喘鳴", "呼吸困難", "チアノーゼ（皮膚が青っぽく変色）", "呼吸停止", "血中酸素飽和度92以下", "締めつけられる感覚", "声がかすれる"]
        case "循環器":
            symptoms = ["不整脈又は徐脈（60回（bpm）未満）", "失神/意識消失", "胸が締め付けられるような感覚", "血圧低下(1歳未満＜70mmHg、\n 1～10歳く［70+（2✕年齢）mmHgl、\n 11歳～成人＜90 mmHg)"]
        case "消化器":
            symptoms = ["嘔吐", "下痢", "腹痛", "血便"]
        case "その他":
            symptoms = ["アナフィラキシー", "発熱", "寒気/硬直/震え", "めまい", "筋肉痛", "充血", "涙", "不機嫌/普段とは違う行動", "関節の痛み", "関節に水が溜まる", "その他"]
        default:
            symptoms = []
        }
    }

    var body: some View {
        List {
            ForEach(symptoms, id: \.self) { symptom in
                if category == "皮膚" {
                    NavigationLink(destination: SelectLocations(category: category, symptom: symptom, selectedSymptoms: $selectedSymptoms)) {
                        symptomRow(symptom: symptom)
                    }
                } else {
                    Button(action: {
                        let symptomWithCategory = "\(category)\(symptom)"
                        if let index = selectedSymptoms.firstIndex(of: symptomWithCategory) {
                            selectedSymptoms.remove(at: index)
                        } else {
                            selectedSymptoms.append(symptomWithCategory)
                        }
                    }) {
                        symptomRow(symptom: symptom)
                    }
                }
            }
        }
        .navigationBarTitle("\(category)")
    }

    func symptomRow(symptom: String) -> some View {
        HStack {
            Text(symptom)
            Spacer()
            if category == "皮膚" {
                Text("\(selectedSymptoms.filter { $0.hasPrefix("\(category)\(symptom)") }.count) ヶ所")
                    .foregroundColor(.gray)
            } else {
                if selectedSymptoms.contains("\(category)\(symptom)") {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

struct SelectSymptoms_Previews: PreviewProvider {
    @State static var selectedSymptoms: [String] = []

    static var previews: some View {
        SelectSymptoms(category: "皮膚", selectedSymptoms: $selectedSymptoms)
    }
}
