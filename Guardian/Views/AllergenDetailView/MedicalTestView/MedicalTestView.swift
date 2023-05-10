//
//  MedicalTestView.swift
//  Guardian
//
//  Created by Teff on 2023/03/23.
//

import SwiftUI
import CloudKit

//MARK: - Struct: Blood Test
struct BloodTest: Identifiable {
    let id = UUID().uuidString
    var bloodTestDate: Date = Date()
    var bloodTestLevel: String = ""
    var bloodTestGrade: BloodTestGrade = .negative
    var record: CKRecord?
    
    init?(record: CKRecord) {
        self.record = record
        guard let bloodTestDate = record["bloodTestDate"] as? Date,
              let bloodTestLevel = record["bloodTestLevel"] as? String,
              let grade = record["bloodTestGrade"] as? String,
              let bloodTestGrade =  BloodTestGrade(rawValue: grade)
        else {
            return
        }
        self.bloodTestDate = bloodTestDate
        self.bloodTestLevel = bloodTestLevel
        self.bloodTestGrade = bloodTestGrade
    }
    init() {
        
    }
    
    init?(entity: BloodTestEntity) {
        let myRecord = CKRecord(recordType: "BloodTest", recordID: CKRecord.ID.init(recordName: entity.recordID!))
        myRecord["bloodTestDate"] = entity.bloodTestDate
        myRecord["bloodTestLevel"] = entity.bloodTestLevel
        myRecord["bloodTestGrade"] = entity.bloodTestGrade
        let allergenID = CKRecord.ID.init(recordName: entity.allergenID!)
        let reference = CKRecord.Reference(recordID: allergenID, action: .deleteSelf)
        myRecord["allergen"] = reference as CKRecordValue
        self.init(record: myRecord)
    }
}
enum BloodTestGrade: String, CaseIterable {
    case negative = "IgEクラス0(陰性)"
    case grade1 = "IgEクラス1(偽陽性)"
    case grade2 = "IgEクラス2(陽性)"
    case grade3 = "IgEクラス3(陽性)"
    case grade4 = "IgEクラス4(陽性)"
    case grade5 = "IgEクラス5(陽性)"
    case grade6 = "IgEクラス6(陽性)"
    
    static func gradeForLevel(_ level: Double) -> BloodTestGrade {
        switch level {
        case 0.0..<0.35:
            return .negative
        case 0.35..<0.7:
            return .grade1
        case 0.7..<3.5:
            return .grade2
        case 3.5..<17.5:
            return .grade3
        case 17.5..<50:
            return .grade4
        case 50..<100:
            return .grade5
        default:
            return .grade6
        }
    }
}

//MARK: - Struct: Skin Test

struct SkinTest: Identifiable {
    let id = UUID()
    var skinTestDate: Date = Date()
    var skinTestResultValue: String = ""
    var skinResult: String = "陰性(-)"
    var record: CKRecord?
    
    init?(record: CKRecord) {
        self.record = record
        guard let skinTestDate = record["skinTestDate"] as? Date,
              let skinTestResultValue = record["skinTestResultValue"] as? String,
              let skinResult = record["skinResult"] as? String
        else {
            return
        }
        self.skinTestDate = skinTestDate
        self.skinTestResultValue = skinTestResultValue
        self.skinResult = skinResult
    }
    init() {
        
    }
    
    init?(entity: SkinTestEntity) {
        let myRecord = CKRecord(recordType: "SkinTest", recordID: CKRecord.ID.init(recordName: entity.recordID!))
        myRecord["skinTestDate"] = entity.skinTestDate
        myRecord["skinTestResultValue"] = entity.skinTestResultValue
        myRecord["skinResult"] = entity.skinResult
        let allergenID = CKRecord.ID.init(recordName: entity.allergenID!)
        let reference = CKRecord.Reference(recordID: allergenID, action: .deleteSelf)
        myRecord["allergen"] = reference as CKRecordValue
        self.init(record: myRecord)
    }
}

//MARK: - Struct: OFC
struct OralFoodChallenge: Identifiable {
    let id = UUID()
    var oralFoodChallengeDate: Date = Date()
    var oralFoodChallengeQuantity: String = ""
    var oralFoodChallengeUnit: String = "g"
    var ofcResult: String = "陰性(-)"
    var record: CKRecord?
    init?(record: CKRecord) {
        self.record = record
        guard let oralFoodChallengeDate = record["oralFoodChallengeDate"] as? Date,
              let oralFoodChallengeQuantity = record["oralFoodChallengeQuantity"] as? String,
              let oralFoodChallengeUnit = record["oralFoodChallengeUnit"] as? String,
              let ofcResult = record["ofcResult"] as? String
        else {
            return
        }
        self.oralFoodChallengeDate = oralFoodChallengeDate
        self.oralFoodChallengeQuantity = oralFoodChallengeQuantity
        self.oralFoodChallengeUnit = oralFoodChallengeUnit
        self.ofcResult = ofcResult
    }
    init() {
        
    }
    init?(entity: OralFoodChallengeEntity) {
        let myRecord = CKRecord(recordType: "OralFoodChallenge", recordID: CKRecord.ID.init(recordName: entity.recordID!))
        myRecord["oralFoodChallengeDate"] = entity.oralFoodChallengeDate
        myRecord["oralFoodChallengeQuantity"] = entity.oralFoodChallengeQuantity
        myRecord["oralFoodChallengeUnit"] = entity.oralFoodChallengeUnit
        myRecord["ofcResult"] = entity.ofcResult
        let allergenID = CKRecord.ID.init(recordName: entity.allergenID!)
        let reference = CKRecord.Reference(recordID: allergenID, action: .deleteSelf)
        myRecord["allergen"] = reference as CKRecordValue
        self.init(record: myRecord)
    }
}

//MARK: - MedicalTestView

enum MedicalTestFormField {
    case bloodTestLevel, skinTestResultValue, oralFoodChallengeQuantity
}

struct MedicalTestView: View {
    @State private var selectedTestIndex = 0
    @EnvironmentObject var medicalTest: MedicalTest
    @State private var deleteIDs: [CKRecord.ID] = []
    @State private var activeAlert: ActiveAlert?
    @State private var isLoading = false
    @State private var isShowingMedicalTestTutorialAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var totalNumberOfMedicalTest: String {
        return "TotalNumberOfMedicalTestData: \(medicalTest.bloodTest.count + medicalTest.skinTest.count + medicalTest.oralFoodChallenge.count)"
    }
    //MARK: - Body View
    
    var body: some View {
        ZStack {
            VStack {
                Picker(selection: $selectedTestIndex, label: Text("Test Category")) {
                    Text("血液検査").tag(0) // Blood Test
                    Text("皮膚プリックテスト").tag(1) // Skin Test
                    Text("経口負荷試験").tag(2) // Oral Food Challenge
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                VStack {
                    if selectedTestIndex == 0 {
                        BloodTestSection(bloodTests: $medicalTest.bloodTest, deleteIDs: $deleteIDs)
                    } else if selectedTestIndex == 1 {
                        SkinTestSection(skinTests: $medicalTest.skinTest, deleteIDs: $deleteIDs)
                    } else {
                        OralFoodChallengeSection(oralFoodChallenges: $medicalTest.oralFoodChallenge, deleteIDs: $deleteIDs)
                    }
                }
                .animation(.default, value: selectedTestIndex)
            }
            .navigationTitle("医療検査記録") // Medical Test
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .none) {
                        saveData { result in
                            switch result {
                            case .success:
                                activeAlert = .saveConfirmation
                            default:
                                activeAlert = .saveError
                            }
                        }
                    } label: {
                        Symbols.done // Save
                    }
                    .alert(item: $activeAlert) { alertType in
                        switch alertType {
                        case .saveConfirmation:
                            return Alert(title: Text("データが保存されました。"), // The data has successfully saved
                                         message: Text(""),
                                         dismissButton: .default(Text("閉じる"), action: {
                                presentationMode.wrappedValue.dismiss()
                            }))
                        default:
                            return Alert(title: Text("Error"), // Please select diagnosis and allergens.
                                         message: Text("Please try again!"),
                                         dismissButton: .default(Text("閉じる")))
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingMedicalTestTutorialAlert = true
                    } label: {
                        Symbols.question
                    }
                    .alert(isPresented: $isShowingMedicalTestTutorialAlert) {
                        Alert(title: Text("医療検査記録"),
                              message: Text("三つの検査結果を記録できます。\n記録されたデータを基にグラフが自動作成されます（今後アップデート予定）\nリスト上で記録内容を削除するには左スワイプしてください。"),
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
    
    //MARK: - Func Save
    func saveData(completion: @escaping ((SaveAlert) -> Void)) {
        let dispatchGroup = DispatchGroup()
        updateData(dispatchGroup: dispatchGroup)
        let newBloodTests = medicalTest.bloodTest.filter { $0.record == nil }
        let newSkinTests = medicalTest.skinTest.filter { $0.record == nil }
        let neworalTests = medicalTest.oralFoodChallenge.filter { $0.record == nil }
        
        // Start Loading
        isLoading = true
        
        for var bloodTest in newBloodTests {
            let myRecord = CKRecord(recordType: "BloodTest")
            
            // Update the bloodTestGrade based on the bloodTestLevel value
            if let level = Double(bloodTest.bloodTestLevel) {
                bloodTest.bloodTestGrade = BloodTestGrade.gradeForLevel(level)
            }
            
            myRecord["bloodTestDate"] = bloodTest.bloodTestDate
            myRecord["bloodTestLevel"] = bloodTest.bloodTestLevel
            myRecord["bloodTestGrade"] = bloodTest.bloodTestGrade.rawValue
            
            let reference = CKRecord.Reference(recordID: medicalTest.allergen.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            dispatchGroup.enter()
            save(record: myRecord) { record in
                DispatchQueue.main.async {
                    bloodTest.record = record
                    if let index = medicalTest.bloodTest.firstIndex(where: { $0.id == bloodTest.id }) {
                        medicalTest.bloodTest[index] = bloodTest
                    }
                }
                dispatchGroup.leave()
            }
        }
        for var test in newSkinTests {
            let myRecord = CKRecord(recordType: "SkinTest")
            
            myRecord["skinTestDate"] = test.skinTestDate
            myRecord["skinTestResultValue"] = test.skinTestResultValue
            myRecord["skinResult"] = test.skinResult
            
            let reference = CKRecord.Reference(recordID: medicalTest.allergen.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            dispatchGroup.enter()
            save(record: myRecord) { record in
                DispatchQueue.main.async {
                    test.record = record
                    if let index = medicalTest.skinTest.firstIndex(where: { $0.id == test.id }) {
                        medicalTest.skinTest[index] = test
                    }
                }
                dispatchGroup.leave()
            }
        }
        for var test in neworalTests {
            let myRecord = CKRecord(recordType: "OralFoodChallenge")
            
            myRecord["oralFoodChallengeDate"] = test.oralFoodChallengeDate
            myRecord["oralFoodChallengeQuantity"] = test.oralFoodChallengeQuantity
            myRecord["oralFoodChallengeUnit"] = test.oralFoodChallengeUnit
            myRecord["ofcResult"] = test.ofcResult
            
            let reference = CKRecord.Reference(recordID: medicalTest.allergen.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            dispatchGroup.enter()
            save(record: myRecord) { record in
                DispatchQueue.main.async {
                    test.record = record
                    if let index = medicalTest.oralFoodChallenge.firstIndex(where: { $0.id == test.id }) {
                        medicalTest.oralFoodChallenge[index] = test
                    }
                }
                dispatchGroup.leave()
            }
        }
        let allergen = medicalTest.allergen
        allergen["totalNumberOfMedicalTests"]  = medicalTest.totalTest
        updateRecord(record: allergen)
        NotificationCenter.default.post(name: NSNotification.Name.init("existingAllergenData"), object: AllergensListModel(record: allergen))
        PersistenceController.shared.addAllergen(allergen: allergen)
        // Stop Loading
        dispatchGroup.notify(queue: .main) {
            self.isLoading = false
            completion(.success)
        }
    }
    func updateRecord(record: CKRecord) {
        CKContainer.default().privateCloudDatabase.modifyRecords(saving: [record], deleting: []) { result in

        }
    }
    //MARK: - Func Update
    func updateData(dispatchGroup: DispatchGroup) {
        let bloodTests = medicalTest.bloodTest.filter { $0.record != nil }
        let skinTests = medicalTest.skinTest.filter { $0.record != nil }
        let oralTests = medicalTest.oralFoodChallenge.filter { $0.record != nil }
        
        // Start Loading
        isLoading = true
        
        var records = [CKRecord]()
        bloodTests.forEach {
            let myRecord = $0.record!
            myRecord["bloodTestDate"] = $0.bloodTestDate
            myRecord["bloodTestLevel"] = $0.bloodTestLevel
            myRecord["bloodTestGrade"] = $0.bloodTestGrade.rawValue
            records.append(myRecord)
        }
        skinTests.forEach {
            let myRecord = $0.record!
            myRecord["skinTestDate"] = $0.skinTestDate
            myRecord["skinTestResultValue"] = $0.skinTestResultValue
            myRecord["skinResult"] = $0.skinResult
            records.append(myRecord)
        }
        oralTests.forEach {
            let myRecord = $0.record!
            myRecord["oralFoodChallengeDate"] = $0.oralFoodChallengeDate
            myRecord["oralFoodChallengeQuantity"] = $0.oralFoodChallengeQuantity
            myRecord["oralFoodChallengeUnit"] = $0.oralFoodChallengeUnit
            myRecord["ofcResult"] = $0.ofcResult
            records.append(myRecord)
        }
        
        let allergen = medicalTest.allergen
        allergen["totalNumberOfMedicalTests"] = medicalTest.bloodTest.count + medicalTest.skinTest.count + medicalTest.oralFoodChallenge.count
        records.append(allergen)
        let modifyRecords = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: deleteIDs)
        modifyRecords.savePolicy = .allKeys
        modifyRecords.queuePriority = .veryHigh
        dispatchGroup.enter()
        modifyRecords.modifyRecordsCompletionBlock = { savedRecord, deletedIDs, error in
            savedRecord?.forEach({ record in
                switch record.recordType {
                case "BloodTest":
                    PersistenceController.shared.addBloodTest(record: record)
                case "SkinTest":
                    PersistenceController.shared.addSkinTest(record: record)
                case "OralFoodChallenge":
                    PersistenceController.shared.addOralFoodChallenge(record: record)
                default:
                    break
                }
            })
            if let deletedIDs = deletedIDs {
                let ids = deletedIDs.map { $0.recordName }
                PersistenceController.shared.deleteBloodTest(recordIDs: ids)
                PersistenceController.shared.deleteSkinTest(recordIDs: ids)
                PersistenceController.shared.deleteOralFoodChallenge(recordIDs: ids)
            }
            dispatchGroup.leave()
            // Stop Loading
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        CKContainer.default().privateCloudDatabase.add(modifyRecords)
    }
    
    private func save(record: CKRecord, completion: @escaping ((CKRecord?) -> Void)) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        CKContainer.default().privateCloudDatabase.save(record) { returnedRecord, returnedError in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            print("Record: \(String(describing: returnedRecord))")
            print("Error: \(String(describing: returnedError))")
            if let record = returnedRecord {
                switch record.recordType {
                case "BloodTest":
                    PersistenceController.shared.addBloodTest(record: record)
                case "SkinTest":
                    PersistenceController.shared.addSkinTest(record: record)
                case "OralFoodChallenge":
                    PersistenceController.shared.addOralFoodChallenge(record: record)
                default:
                    break
                }
            }
            completion(returnedRecord)
        }
    }
}


//MARK: - View: Blood Test Section
struct BloodTestSection: View {
    @Binding var bloodTests: [BloodTest]
    @Binding var deleteIDs: [CKRecord.ID]
    @State private var isShowingBloodTestTutorialAlert = false
    @Environment(\.colorScheme) var colorScheme
    var body: some View {

        VStack {
            List {
                Button {
                    isShowingBloodTestTutorialAlert = true
                } label: {
                    HStack {
                        Text("単位について")
                        Symbols.question
                    }
                    .foregroundColor(.accentColor)
                }
                ForEach($bloodTests) { test in
                    BloodTestFormView(bloodTest: test)
                }
                .onDelete(perform: { indexSet in
                    for index in indexSet {
                        if let id = bloodTests[index].record?.recordID {
                            deleteIDs.append(id)
                        }
                    }
                    bloodTests.remove(atOffsets: indexSet)
                })
            }
            .alert(isPresented: $isShowingBloodTestTutorialAlert) {
                Alert(title: Text("UA/mL = IU/mL = KU/L"),
                      message: Text("どちらも量は同じです。\nKU/Lは欧米でよく使われている単位です。"),
                      dismissButton: .default(Text("閉じる")))
            }
            Button(action: {
                bloodTests.insert(BloodTest(), at: 0) // Add new record at the top
            }) {
                HStack {
                    Spacer()
                    Symbols.addNew
                    Text("新しい記録") // Add New
                    Spacer()
                }
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? Color(.systemBackground) : .white)
                .padding()
                .background(colorScheme == .dark ? Color(.systemBlue).opacity(0.8) : Color.blue)
                .cornerRadius(10)
            }
            .padding(.bottom)
            .padding(.horizontal)
        }
    }
}

//MARK: - View: Skin Test Section
struct SkinTestSection: View {
    @Binding var skinTests: [SkinTest]
    @Binding var deleteIDs: [CKRecord.ID]
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack {
            List {
                ForEach(skinTests.indices, id: \.self) { index in
                    SkinTestFormView(skinTest: $skinTests[index])
                }
                .onDelete(perform: { indexSet in
                    for index in indexSet {
                        if let id = skinTests[index].record?.recordID {
                            deleteIDs.append(id)
                        }
                    }
                    skinTests.remove(atOffsets: indexSet)
                })
            }
            
            Button(action: {
                skinTests.insert(SkinTest(), at: 0) // Add new record at the top
            }) {
                HStack {
                    Spacer()
                    Symbols.addNew
                    Text("新しい記録") // Add New
                    Spacer()
                }
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? Color(.systemBackground) : .white)
                .padding()
                .background(colorScheme == .dark ? Color(.systemBlue).opacity(0.8) : Color.blue)
                .cornerRadius(10)
            }
            .padding(.bottom)
            .padding(.horizontal)
        }
    }
}

//MARK: - View: OFC Section
struct OralFoodChallengeSection: View {
    @Binding var oralFoodChallenges: [OralFoodChallenge]
    @Binding var deleteIDs: [CKRecord.ID]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            List {
                ForEach(oralFoodChallenges.indices, id: \.self) { index in
                    OralFoodChallengeFormView(oralFoodChallenge: $oralFoodChallenges[index])
                }
                .onDelete(perform: { indexSet in
                    for index in indexSet {
                        if let id = oralFoodChallenges[index].record?.recordID {
                            deleteIDs.append(id)
                        }
                    }
                    oralFoodChallenges.remove(atOffsets: indexSet)
                })
            }
            
            
            Button(action: {
                oralFoodChallenges.insert(OralFoodChallenge(), at: 0) // Add new record at the top                
            }) {
                HStack {
                    Spacer()
                    Symbols.addNew
                    Text("新しい記録") // Add New
                    Spacer()
                }
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? Color(.systemBackground) : .white)
                .padding()
                .background(colorScheme == .dark ? Color(.systemBlue).opacity(0.8) : Color.blue)
                .cornerRadius(10)
            }
            .padding(.bottom)
            .padding(.horizontal)
        }
    }
}

//MARK: - Form View: Blood Test

struct BloodTestFormView: View {
    @Binding var bloodTest: BloodTest
    @FocusState private var bloodTestFocusedField: MedicalTestFormField?
    
    private var textFieldBinding: Binding<String> {
        Binding(
            get: { bloodTest.bloodTestGrade.rawValue },
            set: { newValue in
                if let newGrade = BloodTestGrade(rawValue: newValue) {
                    bloodTest.bloodTestGrade = newGrade
                }
            }
        )
    }
    private var currentGradeString: String {
            if let level = Double(bloodTest.bloodTestLevel) {
                let grade = BloodTestGrade.gradeForLevel(level)
                return grade.rawValue
            } else {
                return ""
            }
        }
    
    var body: some View {
        VStack {
            HStack {
                Text("検査日") // BloodTest Date
                Spacer()
                DatePicker("", selection: $bloodTest.bloodTestDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            HStack {
                Text("IgEレベル(UA/mL)") // BloodTest Level
                Spacer()
                CustomTextField(text: $bloodTest.bloodTestLevel,
                                placeholder: "0.0",
                                keyboardType: .phonePad)
                .keyboardType(.decimalPad)
                .submitLabel(.done)
                .focused($bloodTestFocusedField, equals: .bloodTestLevel)
            }
            HStack {
                Text("結果")
                Spacer()
                Text("\(currentGradeString)")
            }
        }
    }
}

//MARK: - Form View: Skin Test

struct SkinTestFormView: View {
    @Binding var skinTest: SkinTest
    @FocusState private var skinTestFocusedField: MedicalTestFormField?
    private let results = ["陰性(-)", "陽性(+)"]
    
    var body: some View {
        VStack {
            HStack {
                Text("検査日") // SkinTest Date
                Spacer()
                DatePicker("", selection: $skinTest.skinTestDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            HStack {
                Text("膨疹直径(mm)") // SkinTest Result Value
                Spacer()
                HStack {
                    Spacer()
                    CustomTextField(text: $skinTest.skinTestResultValue,
                                    placeholder: "0.0",
                                    keyboardType: .phonePad)
                    .keyboardType(.decimalPad)
                    .submitLabel(.done)
                    .focused($skinTestFocusedField, equals: .skinTestResultValue)
                }
            }
            Picker("結果", selection: $skinTest.skinResult) {
                ForEach(results, id: \.self) { result in
                    Text(result)
                        .foregroundColor(.accentColor)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
}

//MARK: - Form View: OFC
struct OralFoodChallengeFormView: View {
    @Binding var oralFoodChallenge: OralFoodChallenge
    @FocusState private var oralFoodChallengeFocusedField: MedicalTestFormField?
    @State private var selectedUnit = "g"
    private let units = ["g", "mL"]
    private let results = ["陰性(-)", "判定保留", "陽性(+)"]
    
    var body: some View {
        VStack {
            HStack {
                Text("検査日")
                Spacer()
                DatePicker("", selection: $oralFoodChallenge.oralFoodChallengeDate, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(CompactDatePickerStyle())
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            HStack {
                Text("総負荷量")
                Spacer()
                CustomTextField(text: $oralFoodChallenge.oralFoodChallengeQuantity, placeholder: "0.0", keyboardType: .phonePad)
                    .keyboardType(.decimalPad)
                    .submitLabel(.done)
                    .focused($oralFoodChallengeFocusedField, equals: .oralFoodChallengeQuantity)
                Picker("単位", selection: $oralFoodChallenge.oralFoodChallengeUnit) {
                    ForEach(units, id: \.self) { unit in
                        Text(unit)
                    }
                }.pickerStyle(MenuPickerStyle())
            }
            HStack {
                Picker("結果", selection: $oralFoodChallenge.ofcResult) {
                    ForEach(results, id: \.self) { result in
                        Text(result)
                            .foregroundColor(.accentColor)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
}

//
//struct MedicalTestView_Previews: PreviewProvider {
//    static var previews: some View {
//        MedicalTestView()
//    }
//}
