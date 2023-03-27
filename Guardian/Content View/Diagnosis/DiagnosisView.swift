//  DiagnosisView.swift

import SwiftUI
import CloudKit

struct DiagnosisView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var diagnosisModel: DiagnosisModel
    
    @State private var showingAddAllergen = false
    @State private var showingRemoveDiagnosisAlert = false
    @State private var showingSaveConfirmationAlert = false
    private let diagnosisOptions = ["即時型IgE抗体アレルギー", "遅延型IgG抗体アレルギー", "アレルギー性腸炎", "好酸球性消化管疾患", "新生児・乳児食物蛋白誘発胃腸症"]
    private let allergenOptions = ["えび", "かに", "小麦", "そば", "卵", "乳", "落花生(ピーナッツ)", "アーモンド", "あわび", "いか", "いくら", "オレンジ", "カシューナッツ", "キウイフルーツ", "牛肉", "くるみ", "ごま", "さけ", "さば", "大豆", "鶏肉", "バナナ", "豚肉", "まつたけ", "もも", "やまいも", "りんご", "ゼラチン"]
    
    @State private var isShowingActionSheet = false
    @State private var isUpdate = false
    init(profile: CKRecord) {
        _diagnosisModel = StateObject(wrappedValue: DiagnosisModel(record: profile))
    }
    init(record: CKRecord) {
        _isUpdate = State(wrappedValue: true)
        _diagnosisModel = StateObject(wrappedValue: DiagnosisModel(diagnosis: record))
    }
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Diagnosis")
                        Spacer()
                        Text(diagnosisModel.diagnosis.isEmpty ? "Please select" : diagnosisModel.diagnosis)
                            .foregroundColor(diagnosisModel.diagnosis.isEmpty ? .secondary : .primary)
                    }
                    .onTapGesture {
                        isShowingActionSheet = true
                    }
                    .actionSheet(isPresented: $isShowingActionSheet) {
                        ActionSheet(title: Text("Select a diagnosis"), buttons: diagnosisOptions.map { option in
                                .default(Text(option)) {
                                    diagnosisModel.diagnosis = option
                                }
                        })
                    }
                }
                Section(header: Text("First Diagnosed")) {
                    DatePicker("Diagnosed Date", selection: $diagnosisModel.diagnosisDate, displayedComponents: .date)
                    TextField("Hospital", text: $diagnosisModel.diagnosedHospital)
                    TextField("Allergist", text: $diagnosisModel.diagnosedAllergist)
                }

                Section(header: Text("Allergens")) {
                    ForEach(diagnosisModel.allergens, id: \.self) { allergen in
                        Text(allergen)
                    }
                    .onDelete(perform: deleteAllergen)
                    Button("Add Allergen") {
                        showingAddAllergen.toggle()
                    }
                    .sheet(isPresented: $showingAddAllergen) {
                        AddAllergenView(allergenOptions: allergenOptions, selectedAllergens: $diagnosisModel.allergens)
                    }
                }
            }
            .navigationTitle("New Diagnosis")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        showingSaveConfirmationAlert.toggle()
                    }
                }
            }
            .toolbar {
                if isUpdate {
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
                                diagnosisModel.deleteItemsFromCloud { isSuccess in
                                    if isSuccess {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }, secondaryButton: .cancel())
                        }
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
                    diagnosisModel.addButtonPressed()

                },
                      secondaryButton: .cancel())
            }
        }
    }
    
    private func deleteAllergen(at offsets: IndexSet) {
        diagnosisModel.allergens.remove(atOffsets: offsets)
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



//struct NewDiagnosis_Previews: PreviewProvider {
//    static var previews: some View {
//        DiagnosisView()
//    }
//}
