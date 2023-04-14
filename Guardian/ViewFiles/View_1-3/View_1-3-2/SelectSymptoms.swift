//
//  SelectSymptoms.swift
//  Guardian
//
//  Created by Teff on 2023/03/22.
//
import SwiftUI

enum AllergySeverity: String {
    case red = "グレード1 (重症)"
    case orange = "グレード2 (中等症)"
    case yellow = "グレード3 (軽症)"
}

struct SelectSymptoms: View {

    let category: String
    @Binding var selectedSymptoms: [String]

    let symptoms: [String]

    @State private var severity: AllergySeverity = .yellow

    init(category: String, selectedSymptoms: Binding<[String]>) {
        self.category = category
        self._selectedSymptoms = selectedSymptoms

        switch category {
        case "皮膚":
            symptoms = ["赤み", "かぶれ", "軽いかゆみ", "腫れ", "強いかゆみ", "じんましん"]
        case "消化器":
            symptoms = ["口や喉のかゆみ・違和感", "弱い腹痛", "吐き気", "嘔吐・下痢(1回)", "強い腹痛(我慢できる)", "嘔吐・下痢(2回)", "咽頭痛", "継続する強い腹痛(我慢できない)", "継続的な嘔吐・下痢"]
        case "呼吸器":
            symptoms = ["鼻水", "くしゃみ", "咳(2回~)", "持続する強い咳き込み", "犬が吠えるような音の咳", "かすれた声", "チアノーゼ(皮膚が青っぽく変色)", "血中酸素飽和度(SpO2)92以下", "喉や胸が締めつけられる感覚", "ゼーゼーする呼吸", "呼吸停止"]
        case "循環器":
            symptoms = ["脈を触れにくい・不整脈", "唇や爪が青白い", "血圧低下(1歳未満: 70mmHg未満、\n 1~10歳: 70+(2✕年齢) mmHgl未満、\n 11歳以上: 90mmHg未満)", "心停止"]
        case "その他":
            symptoms = ["元気がない", "眠気", "軽い頭痛", "恐怖感", "ぐったり", "意識消失", "尿や便を漏らす", "不機嫌/普段とは違う行動", "筋肉痛", "関節の痛み"]
        default:
            symptoms = []
        }
    }

    func judgeSeverity() -> AllergySeverity {
            switch category {
            case "皮膚":
                return selectedSymptoms.filter { $0.hasPrefix("\(category)") }.count >= 5 ? .red : .yellow
            case "消化器":
                if selectedSymptoms.contains(where: { $0.contains("咽頭痛") || $0.contains("継続する強い腹痛(我慢できない)") || $0.contains("継続的な嘔吐・下痢") }) {
                    return .red
                } else if selectedSymptoms.contains(where: { $0.contains("強い腹痛(我慢できる)") || $0.contains("嘔吐・下痢(2回)") }) {
                    return .orange
                } else {
                    return .yellow
                }
            case "呼吸器":
                if selectedSymptoms.contains(where: { $0.contains("持続する強い咳き込み") || $0.contains("犬が吠えるような音の咳") || $0.contains("かすれた声") || $0.contains("チアノーゼ(皮膚が青っぽく変色)") || $0.contains("血中酸素飽和度(SpO2)92以下") || $0.contains("喉や胸が締めつけられる感覚") || $0.contains("ゼーゼーする呼吸") || $0.contains("呼吸停止") }) {
                    return .red
                } else if selectedSymptoms.contains(where: { $0.contains("咳(2回~)") }) {
                    return .orange
                } else {
                    return .yellow
                }
            case "循環器":
                if selectedSymptoms.contains(where: { $0.contains("脈を触れにくい・不整脈") || $0.contains("唇や爪が青白い") || $0.contains("血圧低下(1歳未満: 70mmHg未満、\n 1~10歳: 70+(2✕年齢) mmHgl未満、\n 11歳以上: 90mmHg未満)") || $0.contains("心停止") }) {
                    return .red
                } else {
                    return .yellow
                }
            case "その他":
                if selectedSymptoms.contains(where: { $0.contains("ぐったり") || $0.contains("意識消失") || $0.contains("尿や便を漏らす") }) {
                    return .red
                } else if selectedSymptoms.contains(where: { $0.contains("眠気") || $0.contains("軽い頭痛") || $0.contains("恐怖感") }) {
                    return .orange
                } else {
                    return .yellow
                }
            default:
                return .yellow
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
