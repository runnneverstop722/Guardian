//  DiagnosisView.swift

import SwiftUI
import CloudKit

enum DiagnosisFormField {
    case diagnosedHospital, diagnosedAllergist, diagnosedAllergistComment
}
enum ActiveAlert: Identifiable {
    case saveConfirmation, emptyValidation, saveError
    
    var id: Int {
        switch self {
        case .saveConfirmation:
            return 0
        case .emptyValidation:
            return 1
        case .saveError:
            return 2
        }
    }
}

enum SaveAlert: Identifiable {
    case success, error
    
    var id: Int {
        switch self {
        case .success:
            return 0
        case .error:
            return 1
        }
    }
}


struct DiagnosisView: View {
    
    @StateObject var diagnosisModel: DiagnosisModel
    
    @State private var showingAddAllergen = false
    @State private var showingRemoveDiagnosisAlert = false
    @State private var showingEmptyValidationAlert = false
    @State private var showingSaveConfirmationAlert = false
    @State private var isShowingDiagnosisTutorialAlert = false
    @State private var isPickerPresented: Bool = false
    @State private var selectedImages: [Image] = []
    private let diagnosisOptions = ["即時型IgE抗体アレルギー", "遅延型IgG抗体アレルギー", "アレルギー性腸炎", "好酸球性消化管疾患", "新生児・乳児食物蛋白誘発胃腸症"]
    private let allergenOptions = ["えび", "かに", "小麦", "そば", "卵", "乳", "落花生(ピーナッツ)", "アーモンド", "あわび", "いか", "いくら", "オレンジ", "カシューナッツ", "キウイフルーツ", "牛肉", "くるみ", "ごま", "さけ", "さば", "大豆", "鶏肉", "バナナ", "豚肉", "まつたけ", "もも", "やまいも", "りんご", "ゼラチン"]
    
    @State private var isShowingActionSheet = false
    @State private var isUpdate = false
    @FocusState private var diagnosisFocusedField: DiagnosisFormField?
    @State private var activeAlert: ActiveAlert?
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var isDiagnosisEmpty = true
    
    init(profile: CKRecord) {
        _diagnosisModel = StateObject(wrappedValue: DiagnosisModel(record: profile))
    }
    init(record: CKRecord) {
        _isUpdate = State(wrappedValue: true)
        _diagnosisModel = StateObject(wrappedValue: DiagnosisModel(diagnosis: record))
    }
    private var formValidation: FormValidationDiagnosis {
        FormValidationDiagnosis(isAllergensEmpty: diagnosisModel.allergens.isEmpty, isDiagnosisEmpty: diagnosisModel.diagnosis.isEmpty)
    }
    
    func validateData() -> Bool {
        if diagnosisModel.allergens.isEmpty || diagnosisModel.diagnosis.isEmpty {
            print("Validation failed: Allergens or Diagnosis is empty")
            return false
        }
        print("Validation passed")
        return true
    }
    
    var body: some View {
        ZStack {
            Form {
                Section {
                    HStack {
                        Text("診断名")// Diagnosis Result
                        Spacer()
                        Text(diagnosisModel.diagnosis.isEmpty ? "選択する" : diagnosisModel.diagnosis) // Select
                            .foregroundColor(diagnosisModel.diagnosis.isEmpty ? .secondary : .accentColor)
                            .modifier(RequiredTextStyle(isEmpty: diagnosisModel.diagnosis.isEmpty))
                        
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
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                        TextField("病院名", text: $diagnosisModel.diagnosedHospital) // Hospital Name
                            .submitLabel(.next)
                            .focused($diagnosisFocusedField, equals: .diagnosedHospital)
                        TextField("担当医", text: $diagnosisModel.diagnosedAllergist) // Allergist Name
                            .submitLabel(.next)
                            .focused($diagnosisFocusedField, equals: .diagnosedAllergist)
                        TextField("担当医コメント・指導内容", text: $diagnosisModel.diagnosedAllergistComment) // Allergist Comment
                            .submitLabel(.done)
                            .focused($diagnosisFocusedField, equals: .diagnosedAllergistComment)
                    }
                    .onSubmit {
                        switch diagnosisFocusedField {
                        case .diagnosedHospital:
                            diagnosisFocusedField = .diagnosedAllergist
                        case .diagnosedAllergist:
                            diagnosisFocusedField = .diagnosedAllergistComment
                        default:
                            diagnosisFocusedField = nil
                        }
                    }
                Section(header: HStack {
                    Text("アレルゲン（複数選択可）") // Allergens (Available to select multiply)
                        .font(.headline)
                }) {
                    ForEach(diagnosisModel.allergens, id: \.self) { allergen in
                        Text(allergen)
                    }
                    .onDelete(perform: deleteAllergen)
                    Button(action: {
                        showingAddAllergen.toggle()
                    }) {
                        ZStack {
                            RowBackground(isEmpty: diagnosisModel.allergens.isEmpty)
                            HStack {
                                Symbols.allergens
                                Text("アレルゲンを選択") // Add Allergens
                            }
                        }
                    }
                    .sheet(isPresented: $showingAddAllergen) {
                        AddAllergenView(allergenOptions: allergenOptions, selectedAllergens: $diagnosisModel.allergens, selectedItems: Set($diagnosisModel.allergens.wrappedValue))
                    }
                }
                
                
                Section(header: Text("添付写真")
                    .font(.headline)) { // Picture Attachment
                        Button(action: {
                            isPickerPresented = true
                        }) {
                            HStack{
                                Image(systemName: "photo")
                                Text("写真を選択") // Select Images
                                Spacer()
                                Text("選択中: \(diagnosisModel.diagnosisImages.count)") // Selected Items
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .sheet(isPresented: $isPickerPresented) {
                            DiagnosisPhotoPicker(selectedImages: $diagnosisModel.diagnosisImages)
                        }
                        
                        // Display the selected image thumbnails
                        ScrollView(.horizontal) {
                            VStack(alignment: .leading) {
                                HStack {
                                    ForEach(diagnosisModel.diagnosisImages, id: \.data) { diagnosisImage in
                                        if let uiImage = UIImage(data: diagnosisImage.data) {
                                            ZStack(alignment: .topTrailing) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipped()
                                                Button {
                                                    diagnosisModel.diagnosisImages.removeAll { $0.id == diagnosisImage.id }
                                                } label: {
                                                    Image(systemName: "x.circle.fill")
                                                        .resizable()
                                                        .foregroundColor(.red)
                                                        .scaledToFit()
                                                        .frame(width: 30, height: 30)
                                                        .clipped()
                                                }
                                            }
                                        } else {
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                        }
                                    }
                                }
                                LazyVGrid(columns: createAdaptiveColumns(), spacing: 10) {
                                    ForEach(selectedImages.indices, id: \.self) { index in
                                        selectedImages[index]
                                            .resizable()
                                            .scaledToFit()
                                            .cornerRadius(8)
                                            .shadow(radius: 4)
                                    }
                                }
                            }
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
                        Alert(title: Text("診断記録を削除しますか？"),
                              message: Text(""),
                              primaryButton: .destructive(Text("削除")) {
                            diagnosisModel.deleteItemsFromCloud { isSuccess in
                                DispatchQueue.main.async {
                                    if isSuccess {
                                        dismiss.callAsFunction()
                                    } else {
                                        print("Failed to delete Diagnosis item.")
                                    }
                                }
                            }
                        }, secondaryButton: .cancel(Text("キャンセル")))
                    }
                }
            }
            .keyboardDismissGesture()
            .navigationBarTitle("診断記録") // Diagnosis
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button() {
                        let validation = formValidation
                        if validation.validateForm() {
                            isLoading = true
                            diagnosisModel.addButtonPressed { result in
                                DispatchQueue.main.async {
                                    isLoading = false
                                    switch result {
                                    case .success:
                                        activeAlert = .saveConfirmation
                                    default:
                                        activeAlert = .saveError
                                        break
                                    }
                                }
                            }
                        } else {
                            activeAlert = .emptyValidation
                        }
                    } label: {
                        Symbols.done // Save
                    }
                    .alert(item: $activeAlert) { alertType in
                        switch alertType {
                        case .saveConfirmation:
                            return Alert(title: Text("データが保存されました。"),
                                         message: Text(""),
                                         dismissButton: .default(Text("閉じる"), action: {
                                
                                presentationMode.wrappedValue.dismiss()
                            }))
                        case .emptyValidation:
                            return Alert(title: Text("入力エラー"),
                                         message: Text(formValidation.getEmptyFieldsMessage()),
                                         dismissButton: .default(Text("閉じる")))
                        case .saveError:
                            return Alert(title: Text("もう一度試してください。"),
                                         message: Text(""),
                                         dismissButton: .default(Text("閉じる")))
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingDiagnosisTutorialAlert = true
                    } label: {
                        Symbols.question
                    }
                    .alert(isPresented: $isShowingDiagnosisTutorialAlert) {
                        Alert(title: Text("診断記録とは？"),
                              message: Text("初めて医師より食物アレルギーと\n診断された際に記録します。\n５つの診断名から選択できます。\n\n- 即時型IgE抗体アレルギー\n- 遅延型IgG抗体アレルギー\n- アレルギー性腸炎\n- 好酸球性消化管疾患\n- 新生児・乳児食物蛋白誘発胃腸症"),
                              dismissButton: .default(Text("閉じる")))
                    }
                }
            }
            if isLoading {
                Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
                LoadingAlert()
            }
        }
    }
    
    private func deleteAllergen(at offsets: IndexSet) {
        diagnosisModel.allergens.remove(atOffsets: offsets)
    }
    
    private func createAdaptiveColumns() -> [GridItem] {
        let minWidth: CGFloat = 100
        let spacing: CGFloat = 10
        let adaptiveColumns = [
            GridItem(.adaptive(minimum: minWidth, maximum: minWidth), spacing: spacing)
        ]
        return adaptiveColumns
    }
}

//struct NewDiagnosis_Previews: PreviewProvider {
//    static var previews: some View {
//        DiagnosisView()
//    }
//}
