//
//  AddAllergenView.swift
//  Guardian
//
//  Created by Teff on 2023/03/22.
//

import SwiftUI

struct AddAllergenView: View {
    let allergenOptions: [String]
    @Binding var selectedAllergen: [String]
    @State private var selected: String = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Select Allergen")
                .font(.headline)
            Picker("Allergen", selection: $selected) {
                ForEach(allergenOptions, id: \.self) { allergen in
                    Text(allergen)
                }
            }
            .labelsHidden()
            .pickerStyle(WheelPickerStyle())
            
            Button("Add") {
                selectedAllergen.append(selected)
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
        }
        .padding()
    }
}

struct AddAllergenView_Previews: PreviewProvider {
    @State static private var sampleAllergens: [String] = []

    static var previews: some View {
        AddAllergenView(allergenOptions: ["えび", "かに", "小麦", "そば", "卵", "乳", "落花生(ピーナッツ)", "アーモンド", "あわび", "いか", "いくら", "オレンジ", "カシューナッツ", "キウ イフルーツ", "牛肉", "くるみ", "ごま", "さけ", "さば", "大豆", "鶏肉", "バナナ", "豚肉", "まつたけ", "もも", "やまいも", "りんご", "ゼラチン"], selectedAllergen: $sampleAllergens)
    }
}
