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
}
enum BloodTestGrade: String, CaseIterable {
    case negative = "クラス0(陰性)"
    case grade1 = "クラス1(偽陽性)"
    case grade2 = "クラス2(陽性)"
    case grade3 = "クラス3(陽性)"
    case grade4 = "クラス4(陽性)"
    case grade5 = "クラス5(陽性)"
    case grade6 = "クラス6(陽性)"
    
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
    var skinTestResult: Bool = false
    var record: CKRecord?
    
    init?(record: CKRecord) {
        self.record = record
        guard let skinTestDate = record["skinTestDate"] as? Date,
              let skinTestResultValue = record["skinTestResultValue"] as? String,
              let skinTestResult = record["skinTestResult"] as? Bool
        else {
            return
        }
        self.skinTestDate = skinTestDate
        self.skinTestResultValue = skinTestResultValue
        self.skinTestResult = skinTestResult
    }
    init() {
        
    }
}

//MARK: - Struct: OFC
struct OralFoodChallenge: Identifiable {
    let id = UUID()
    var oralFoodChallengeDate: Date = Date()
    var oralFoodChallengeQuantity: String = ""
    var oralFoodChallengeResult: Bool = false
    var record: CKRecord?
    init?(record: CKRecord) {
        self.record = record
        guard let oralFoodChallengeDate = record["oralFoodChallengeDate"] as? Date,
              let oralFoodChallengeQuantity = record["oralFoodChallengeQuantity"] as? String,
              let oralFoodChallengeResult = record["oralFoodChallengeResult"] as? Bool
        else {
            return
        }
        self.oralFoodChallengeDate = oralFoodChallengeDate
        self.oralFoodChallengeQuantity = oralFoodChallengeQuantity
        self.oralFoodChallengeResult = oralFoodChallengeResult
    }
    init() {
        
    }
}

//MARK: - MedicalTestView

enum MedicalTestFormField {
    case bloodTestLevel, skinTestResultValue, oralFoodChallengeQuantity
}

struct MedicalTestView: View {
    @State private var selectedTestIndex = 0
    @EnvironmentObject var mediacalTest: MedicalTest
    @State private var deleteIDs: [CKRecord.ID] = []
    @State private var showingAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var totalNumberOfMedicalTest: String {
        return "TotalNumberOfMedicalTestData: \(mediacalTest.bloodTest.count + mediacalTest.skinTest.count + mediacalTest.oralFoodChallenge.count)"
    }
    //MARK: - Body View
    
    var body: some View {
        VStack {
            Picker(selection: $selectedTestIndex, label: Text("Test Category")) {
                Text("血液検査").tag(0) // Blood Test
                Text("皮膚プリックテスト").tag(1) // Skin Test
                Text("食物経口負荷試験").tag(2) // Oral Food Challenge
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            VStack {
                if selectedTestIndex == 0 {
                    BloodTestSection(bloodTests: $mediacalTest.bloodTest, deleteIDs: $deleteIDs)
                } else if selectedTestIndex == 1 {
                    SkinTestSection(skinTests: $mediacalTest.skinTest, deleteIDs: $deleteIDs)
                } else {
                    OralFoodChallengeSection(oralFoodChallenges: $mediacalTest.oralFoodChallenge, deleteIDs: $deleteIDs)
                }
            }
            .animation(.default, value: selectedTestIndex)
        }
        .navigationTitle("医療検査記録") // Medical Test
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .none) {
                    showingAlert = true
                } label: {
                    Symbols.done // Save
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("データが保存されました。"), // Succeccfully Saved
                          message: Text(""),
                          dismissButton: .default(Text("閉じる"), action: { // Close
                        saveData()
                        presentationMode.wrappedValue.dismiss()
                    }))
                }
            }
        }
    }
    
    //MARK: - Func Save
    func saveData() {
        updateData()
        
        let newBloodTests = mediacalTest.bloodTest.filter { $0.record == nil }
        let newSkinTests = mediacalTest.skinTest.filter { $0.record == nil }
        let neworalTests = mediacalTest.oralFoodChallenge.filter { $0.record == nil }
        
        for var bloodTest in newBloodTests {
            let myRecord = CKRecord(recordType: "BloodTest")
            
            // Update the bloodTestGrade based on the bloodTestLevel value
            if let level = Double(bloodTest.bloodTestLevel) {
                bloodTest.bloodTestGrade = BloodTestGrade.gradeForLevel(level)
            }
            
            myRecord["bloodTestDate"] = bloodTest.bloodTestDate
            myRecord["bloodTestLevel"] = bloodTest.bloodTestLevel
            myRecord["bloodTestGrade"] = bloodTest.bloodTestGrade.rawValue
            
            let reference = CKRecord.Reference(recordID: mediacalTest.allergen.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            // Save the record to CloudKit
            save(record: myRecord)
        }
//        newBloodTests.forEach {
//            let myRecord = CKRecord(recordType: "BloodTest")
//            if let level = Double($0.bloodTestLevel) {
//                $0.bloodTestGrade = BloodTestGrade.gradeForLevel(level)
//            }
//            myRecord["bloodTestDate"] = $0.bloodTestDate
//            myRecord["bloodTestLevel"] = $0.bloodTestLevel
//            myRecord["bloodTestGrade"] = $0.bloodTestGrade.rawValue
//
//            let reference = CKRecord.Reference(recordID: mediacalTest.allergen.recordID, action: .deleteSelf)
//            myRecord["allergen"] = reference as CKRecordValue
//            save(record: myRecord)
//        }
        newSkinTests.forEach {
            let myRecord = CKRecord(recordType: "SkinTest")
            
            myRecord["skinTestDate"] = $0.skinTestDate
            myRecord["skinTestResultValue"] = $0.skinTestResultValue
            myRecord["skinTestResult"] = $0.skinTestResult
            
            let reference = CKRecord.Reference(recordID: mediacalTest.allergen.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            save(record: myRecord)
        }
        neworalTests.forEach {
            let myRecord = CKRecord(recordType: "OralFoodChallenge")
            
            myRecord["oralFoodChallengeDate"] = $0.oralFoodChallengeDate
            myRecord["oralFoodChallengeQuantity"] = $0.oralFoodChallengeQuantity
            myRecord["oralFoodChallengeResult"] = $0.oralFoodChallengeResult
            
            let reference = CKRecord.Reference(recordID: mediacalTest.allergen.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            save(record: myRecord)
        }
    }
    
    //MARK: - Func Update
    func updateData() {
        let bloodTests = mediacalTest.bloodTest.filter { $0.record != nil }
        let skinTests = mediacalTest.skinTest.filter { $0.record != nil }
        let oralTests = mediacalTest.oralFoodChallenge.filter { $0.record != nil }
        
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
            myRecord["skinTestResult"] = $0.skinTestResult
            records.append(myRecord)
        }
        oralTests.forEach {
            let myRecord = $0.record!
            myRecord["oralFoodChallengeDate"] = $0.oralFoodChallengeDate
            myRecord["oralFoodChallengeQuantity"] = $0.oralFoodChallengeQuantity
            myRecord["oralFoodChallengeResult"] = $0.oralFoodChallengeResult
            records.append(myRecord)
        }
        
        let allergen = mediacalTest.allergen
        allergen["totalNumberOfMedicalTests"] = mediacalTest.bloodTest.count + mediacalTest.skinTest.count + mediacalTest.oralFoodChallenge.count
        records.append(allergen)
        CKContainer.default().privateCloudDatabase.modifyRecords(saving: records, deleting: deleteIDs) { result in
            
        }
    }
    
    private func save(record: CKRecord) {
        CKContainer.default().privateCloudDatabase.save(record) { returnedRecord, returnedError in
            print("Record: \(String(describing: returnedRecord))")
            print("Error: \(String(describing: returnedError))")
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
            }
            .padding(.bottom)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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
            }
            .padding(.bottom)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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
            }
            .padding(.bottom)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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
                Text("IgEクラス")
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
                Text("結果(mm)") // SkinTest Result Value
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
            HStack {
                Text("陽性有無") // SkinTest Result
                Spacer()
                Toggle("", isOn: $skinTest.skinTestResult)
                    .toggleStyle(SwitchToggleStyle())
            }
        }
    }
}

//MARK: - Form View: OFC
struct OralFoodChallengeFormView: View {
    @Binding var oralFoodChallenge: OralFoodChallenge
    @FocusState private var oralFoodChallengeFocusedField: MedicalTestFormField?
    
    var body: some View {
        VStack {
            HStack {
                Text("検査日") // OralFoodChallenge Date
                Spacer()
                DatePicker("", selection: $oralFoodChallenge.oralFoodChallengeDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .environment(\.locale, Locale(identifier: "ja_JP"))
            }
            HStack {
                Text("食べた量(mm)") // OralFoodChallenge Quantity
                Spacer()
                CustomTextField(text: $oralFoodChallenge.oralFoodChallengeQuantity,
                                placeholder: "0.0",
                                keyboardType: .phonePad)
                .keyboardType(.decimalPad)
                .submitLabel(.done)
                .focused($oralFoodChallengeFocusedField, equals: .oralFoodChallengeQuantity)
            }
            HStack {
                Text("症状有無") // OralFoodChallenge Result
                Spacer()
                Toggle("", isOn: $oralFoodChallenge.oralFoodChallengeResult)
                    .toggleStyle(SwitchToggleStyle())
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
