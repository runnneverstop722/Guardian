//  DiagnosisView.swift

import SwiftUI
import CloudKit

struct DiagnosisView: View {
    
    @StateObject var diagnosisModel: DiagnosisModel
    
    @State private var showingAddAllergen = false
    @State private var showingRemoveDiagnosisAlert = false
    @State private var showingSaveConfirmationAlert = false
    private let diagnosisOptions = ["即時型IgE抗体アレルギー", "遅延型IgG抗体アレルギー", "アレルギー性腸炎", "好酸球性消化管疾患", "新生児・乳児食物蛋白誘発胃腸症"]
    private let allergenOptions = ["えび", "かに", "小麦", "そば", "卵", "乳", "落花生(ピーナッツ)", "アーモンド", "あわび", "いか", "いくら", "オレンジ", "カシューナッツ", "キウイフルーツ", "牛肉", "くるみ", "ごま", "さけ", "さば", "大豆", "鶏肉", "バナナ", "豚肉", "まつたけ", "もも", "やまいも", "りんご", "ゼラチン"]
    
    @State private var isShowingActionSheet = false
    @State private var isUpdate = false
    @Environment(\.presentationMode) var presentationMode
    
    init(profile: CKRecord) {
        _diagnosisModel = StateObject(wrappedValue: DiagnosisModel(record: profile))
    }
    init(record: CKRecord) {
        _isUpdate = State(wrappedValue: true)
        _diagnosisModel = StateObject(wrappedValue: DiagnosisModel(diagnosis: record))
    }
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("診断名") // Diagnosis Result
                    Spacer()
                    Text(diagnosisModel.diagnosis.isEmpty ? "選択する" : diagnosisModel.diagnosis) // Select
                        .foregroundColor(diagnosisModel.diagnosis.isEmpty ? .secondary : .accentColor)
                }
                .onTapGesture {
                    isShowingActionSheet = true
                }
                .actionSheet(isPresented: $isShowingActionSheet) {
                    ActionSheet(title: Text("診断結果を選択してください。"), buttons: diagnosisOptions.map { option in // Select the diagnosis result
                            .default(Text(option)) {
                                diagnosisModel.diagnosis = option
                            }
                    } + [.cancel(Text("キャンセル"))]) // Cancel
                }
            }
            Section(header: Text("医療機関")
                .font(.headline)) { // Medical Facility
                DatePicker("診断日", selection: $diagnosisModel.diagnosisDate, displayedComponents: .date) // Diagnosis Date
                TextField("病院名", text: $diagnosisModel.diagnosedHospital) // Hospital Name
                TextField("担当医", text: $diagnosisModel.diagnosedAllergist) // Allergist Name
            }
            
            Section(header: Text("アレルゲン（複数選択可）")
                .font(.headline)) {
                ForEach(diagnosisModel.allergens, id: \.self) { allergen in
                    Text(allergen)
                }
                .onDelete(perform: deleteAllergen)
                Button(action: {
                    showingAddAllergen.toggle()
                }) {
                    HStack {
                        Image(systemName: "allergens")
                        Text("アレルゲンを追加")
                    }
                }
                .sheet(isPresented: $showingAddAllergen) {
                    AddAllergenView(allergenOptions: allergenOptions, selectedAllergens: $diagnosisModel.allergens, selectedItems: Set($diagnosisModel.allergens.wrappedValue))
                }
            }
            
            if isUpdate {
                
                Button(action: {
                    showingRemoveDiagnosisAlert.toggle()
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "trash")
                        Text("この診断記録を削除する")
                        Spacer()
                    }
                    .foregroundColor(.red)
                }
                .alert(isPresented: $showingRemoveDiagnosisAlert) {
                    Alert(title: Text(""),
                          message: Text("医療検査・発症記録を削除します。\nよろしいですか？"),
                          primaryButton: .destructive(Text("削除")) {
                        // Handle removal of diagnosis
                        diagnosisModel.deleteItemsFromCloud { isSuccess in
                            if isSuccess {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }, secondaryButton: .cancel(Text("キャンセル")))
                }
            }
        }
        .navigationBarTitle("診断記録")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button() {
                    showingSaveConfirmationAlert.toggle()
                } label: {
                    Text("完了")
                }
                .alert(isPresented: $showingSaveConfirmationAlert) {
                    Alert(title: Text("データが保存されました。"),
                          message: Text(""),
                          dismissButton: .default(Text("閉じる"), action: {
                        diagnosisModel.addButtonPressed()
                        presentationMode.wrappedValue.dismiss()
                    }))
                }
            }
        }
    }
    
    private func deleteAllergen(at offsets: IndexSet) {
        diagnosisModel.allergens.remove(atOffsets: offsets)
    }
}



//struct NewDiagnosis_Previews: PreviewProvider {
//    static var previews: some View {
//        DiagnosisView()
//    }
//}
