//
//  AddAllergenView.swift
//  Guardian
//
//  Created by Teff on 2023/03/22.
//

import SwiftUI

struct AddAllergenView: View {
    let allergenOptions: [String]
    @Binding var selectedAllergens: [String]
    @Environment(\.presentationMode) var presentationMode
    @State var selectedItems = Set<String>()
    
    var body: some View {
        NavigationView {
            List(allergenOptions, id: \.self, selection: $selectedItems) { item in
                Text(item)
            }
            .navigationBarTitle("アレルゲン選択(複数可)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("確認") {
                        selectedAllergens = []
                        selectedAllergens.append(contentsOf: selectedItems)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .listStyle(PlainListStyle())
            .environment(\.editMode, .constant(EditMode.active))
        }
    }
}
