//
//  DiagnosisView.swift
//  Guardian
//
//  Created by Teff on 2023/03/24.
//

import SwiftUI

struct DiagnosisView: View {
    
    @State private var diagnosis: String = ""
    @State private var diagnosisDate = Date()
    @State private var diagnosedHospital: String = ""
    @State private var diagnosedAllergist: String = ""
    @State private var allergens: [String] = []
    
    @State private var showingAddAllergen = false
    @State private var showingRemoveDiagnosisAlert = false
    @State private var showingSaveConfirmationAlert = false
    
    private let diagnosisOptions = ["即時型IgE抗体アレルギー", "遅延型IgG抗体アレルギー", "アレルギー性腸炎", "好酸球性消化管疾患", "食物たんぱく誘発胃腸症（消化管アレルギー）"]
    private let allergenOptions = ["えび", "かに", "小麦", "そば", "卵", "乳", "落花生(ピーナッツ)", "アーモンド", "あわび", "いか", "いくら", "オレンジ", "カシューナッツ", "キウイフルーツ", "牛肉", "くるみ", "ごま", "さけ", "さば", "大豆", "鶏肉", "バナナ", "豚肉", "まつたけ", "もも", "やまいも", "りんご", "ゼラチン"]
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Diagnosis", selection: $diagnosis) {
                        ForEach(diagnosisOptions, id: \.self) { option in
                            Text(option)
                        }
                    }
                }
                
                Section(header: Text("First Diagnosed")) {
                    DatePicker("Diagnosed Date", selection: $diagnosisDate, displayedComponents: .date)
                    TextField("Hospital", text: $diagnosedHospital)
                    TextField("Allergist", text: $diagnosedAllergist)
                }
                
                Section(header: Text("Allergens")) {
                    ForEach(allergens, id: \.self) { allergen in
                        Text(allergen)
                    }
                    .onDelete(perform: deleteAllergen)
                    Button("Add Allergen") {
                        showingAddAllergen.toggle()
                    }
                    .sheet(isPresented: $showingAddAllergen) {
                        AddAllergenView(allergenOptions: allergenOptions, selectedAllergens: $allergens)
                    }
                }
                
            }
            .navigationTitle("Diagnosis")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        showingSaveConfirmationAlert.toggle()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        showingRemoveDiagnosisAlert.toggle()
                    }) {
                        Text("Remove this diagnosis")
                            .foregroundColor(.red)
                    }
                    .alert(isPresented: $showingRemoveDiagnosisAlert) {
                        Alert(title: Text("Remove this diagnosis?"), message: Text("This action cannot be undone."), primaryButton: .destructive(Text("Remove")) {
                            // Handle removal of diagnosis
                        }, secondaryButton: .cancel())
                    }
                }
            }
            .alert(isPresented: $showingSaveConfirmationAlert) {
                Alert(title: Text("Save Diagnosis?"),
                      message: Text("Do you want to save this diagnosis?"),
                      primaryButton: .default(Text("Save")) {
                    // Save the diagnosis
                    // Save Episode to CloudKit
                    // Save the data to the variables you mentioned:
                    // episodeDate, firstKnownExposure(Bool), wentToHospital(Bool),
                    // typeOfExposure([String]), symptoms([String]), leadTimeToSymptoms(String), treatments([String])
                },
                      secondaryButton: .cancel())
            }
        }
    }
    
    private func deleteAllergen(at offsets: IndexSet) {
        allergens.remove(atOffsets: offsets)
    }
    
    struct AddAllergenView: View {
        let allergenOptions: [String]
        @Binding var selectedAllergens: [String]
        @Environment(\.presentationMode) var presentationMode
        @State private var selectedItems = Set<String>()
        
        var body: some View {
            NavigationView {
                List(allergenOptions, id: \.self, selection: $selectedItems) { item in
                    Text(item)
                }
                .navigationBarTitle("Select Allergens")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
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
}

struct DiagnosisView_Previews: PreviewProvider {
    static var previews: some View {
        DiagnosisView()
    }
}
