//
//  SelectLocations.swift
//  Guardian
//
//  Created by Teff on 2023/03/22.
//
import SwiftUI

struct SelectLocations: View {
    let category: String
    let symptom: String
    @Binding var selectedSymptoms: [String]

    let locations = ["Ear", "Lips", "Tongue", "Throat", "Hands", "Feet", "Legs", "Arms", "Trunk", "Genitalia"]
    
    var body: some View {
        List {
            ForEach(locations, id: \.self) { location in
                Button(action: {
                    let symptomLocation = "\(category)\(symptom)\(location)"
                    if let index = selectedSymptoms.firstIndex(of: symptomLocation) {
                        selectedSymptoms.remove(at: index)
                    } else {
                        selectedSymptoms.append(symptomLocation)
                    }
                }) {
                    HStack {
                        Text(location)
                        Spacer()
                        if selectedSymptoms.contains("\(category)\(symptom)\(location)") {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
        .navigationBarTitle("\(symptom) Locations")
    }
}

struct SelectLocations_Previews: PreviewProvider {
    @State static var selectedSymptoms: [String] = []

    static var previews: some View {
        SelectLocations(category: "Skin", symptom: "Rash", selectedSymptoms: $selectedSymptoms)
    }
}
