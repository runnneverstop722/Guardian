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
        case "Skin":
            symptoms = ["Rash", "Hives", "Itching", "Flushing or redness", "Burning", "Swelling, Edema, or angioedema"]
        case "Nose or breathing":
            symptoms = ["Runny nose", "Congestion or stuffy nose", "Mouth or palate itching", "Sneezing", "Cough", "Chest pain", "Chest tightness", "Wheezing", "Shortness of breath", "Throat tightness"]
        case "Heart":
            symptoms = ["Irregular heart beat or palpitations", "Fainting or loss of consciousness", "Chest pain or chest tightness", "Low blood pressure"]
        case "Abdominal":
            symptoms = ["Nausea and/or vomiting", "Diarrhea", "Abdominal pain", "Blood or mucus in stool"]
        case "Other":
            symptoms = ["Anaphylaxis", "Fevers", "Chills or rigors or shakes", "Dizziness or lightheadedness", "Muscle aches", "Mental status change or abnormal behavior", "Liver injury", "Kidney injury", "Joint pain", "Joint swelling", "Other"]
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
