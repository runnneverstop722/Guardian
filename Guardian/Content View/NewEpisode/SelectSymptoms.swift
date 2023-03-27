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
        case "皮膚・粘膜":
            symptoms = ["かぶれ", "じんましん", "かゆみ", "紅潮又は赤み", "Burning", ""]
        case "呼吸器":
            symptoms = ["間欠的な咳", "鼻閉（鼻つまり）", "くしゃみ", "断統的な咳", "持続する強い咳き込み", "犬吠様咳嗽（犬が吠えたような鳴き声の咳）", "聴診上の喘鳴", "軽い息苦しさ", "明らかな喘鳴", "呼吸困難", "チアノーゼ（皮膚が青っぽく変色）", "呼吸停止", "血中酸素飽和度92以下", "締めつけられる感覚", "嗄声(声がれ)"]
        case "循環器":
            symptoms = ["不整脈又は徐脈（60回（bpm）未満）", "Fainting or loss of consciousness", "Chest pain or chest tightness", "血圧低下(1歳未満＜70mmHg、1～10歳く［70+（2✕年齢）mmHgl、11歳～成人＜90 mmHg)"]
        case "消化器":
            symptoms = ["Nausea and/or vomiting", "Diarrhea", "Abdominal pain", "Blood or mucus in stool"]
        case "その他":
            symptoms = ["アナフィラキシー", "発熱", "Chills or rigors or shakes", "Dizziness or lightheadedness", "Muscle aches", "Mental status change or abnormal behavior", "Liver injury", "Kidney injury", "Joint pain", "Joint swelling", "Other"]
        default:
            symptoms = []
        }
    }

    var body: some View {
        List {
            ForEach(symptoms, id: \.self) { symptom in
                if category == "Skin" {
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
        .navigationBarTitle("\(category) Symptoms")
    }

    func symptomRow(symptom: String) -> some View {
        HStack {
            Text(symptom)
            Spacer()
            if category == "Skin" {
                Text("\(selectedSymptoms.filter { $0.hasPrefix("\(category)\(symptom)") }.count) locations")
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
        SelectSymptoms(category: "Skin", selectedSymptoms: $selectedSymptoms)
    }
}
