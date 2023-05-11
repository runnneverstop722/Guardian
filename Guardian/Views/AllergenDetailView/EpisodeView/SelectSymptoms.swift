//
//  SelectSymptoms.swift
//  Guardian
//
//  Created by Teff on 2023/03/22.
//
import SwiftUI

struct SelectSymptoms: View {
    @Binding var selectedSymptoms: [String]
    let symptoms: [String]
    let category: String
    
    init(category: String, selectedSymptoms: Binding<[String]>) {
        self.category = category
        self._selectedSymptoms = selectedSymptoms
        
        switch category {
        case "皮膚":
            symptoms = ["🟡部分的な赤み", "🟡部分的なかゆみ", "🟡部分的なじんましん", "🟠広範囲の赤み", "🟠広範囲のかゆみ", "🟠広範囲のじんましん"]
        case "粘膜":
            symptoms = ["🟡唇や瞼(まぶた)の腫れ", "🟡⼝や喉の違和感・かゆみ", "🟠強い唇や瞼(まぶた)", "🟠顔全体の腫れ", "🟠飲み込み⾟さ", "🔴声枯れ", "🔴声が出ない", "🔴喉や胸が強く締めつけられる感覚"]
        case "消化器":
            symptoms = ["🟡軽い(我慢できる)お腹の痛み", "🟡吐き気", "🟠中程度(我慢できる)のお腹の痛み", "🟠嘔吐(1~2回)", "🟠下痢(1~2回)", "🟠咽頭痛", "🔴連続する強い(我慢できない)お腹の痛み", "🔴繰り返し吐き続ける"]
        case "呼吸器":
            symptoms = ["🟡鼻水", "🟡鼻詰まり", "🟡くしゃみ", "🟡弱く連続しない咳", "🟠時々連続する咳・咳き込み", "🔴持続する強い咳き込み", "🔴犬が吠えるような音の咳", "🔴チアノーゼ(皮膚が青っぽく変色)", "🔴血中酸素飽和度(SpO2)92以下", "🔴ぜん鳴(ゼーゼー、ヒューヒュー)", "🔴呼吸困難"]
        case "循環器":
            symptoms = ["🟠蒼白(そうはく)", "🔴脈を触れにくい・不整脈", "🔴唇や爪が青白い", "🔴血圧低下\n ・1歳未満: 70mmHg未満、\n ・1~10歳: 70+(2✕年齢) mmHgl未満、\n ・11歳以上: 90mmHg未満)", "🔴心停止"]
        case "神経":
            symptoms = ["🟡やや元気がない", "🟠明らかに元気がない", "🟠眠気", "🟠軽い頭痛", "🟠恐怖感", "🔴ぐったり", "🔴意識もうろう", "🔴意識消失", "🔴尿や便を漏らす"]
        default:
            symptoms = []
        }
    }
    
    var body: some View {
        List {
            ForEach(symptoms, id: \.self) { symptom in
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
        .navigationBarTitle("\(category)")
    }
    
    func symptomRow(symptom: String) -> some View {
        HStack {
            Text(symptom)
            Spacer()
            if selectedSymptoms.contains("\(category)\(symptom)") {
                Symbols.done
            }
        }
    }
}
