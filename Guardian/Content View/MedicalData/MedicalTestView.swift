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
    case negative = "陰性(~0.35)"
    case grade1 = "1グレード"
    case grade2 = "2グレード"
    case grade3 = "3グレード"
    case grade4 = "4グレード"
    case grade5 = "5グレード"
    case grade6 = "6グレード"
}

//MARK: - Struct: Skin Test

struct SkinTest: Identifiable {
    let id = UUID()
    var skinTestDate: Date = Date()
    var SkinTestResultValue: String = ""
    var SkinTestResult: Bool = false
    var record: CKRecord?
    
    init?(record: CKRecord) {
        self.record = record
        guard let skinTestDate = record["skinTestDate"] as? Date,
              let SkinTestResultValue = record["SkinTestResultValue"] as? String,
              let SkinTestResult = record["SkinTestResult"] as? Bool
        else {
            return
        }
        self.skinTestDate = skinTestDate
        self.SkinTestResultValue = SkinTestResultValue
        self.SkinTestResult = SkinTestResult
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

struct MedicalTestView: View {
    @State private var selectedTestIndex = 0
    @EnvironmentObject var mediacalTest: MedicalTest
    @State private var deleteIDs: [CKRecord.ID] = []
    //    private var bloodTestObjects: [CKRecord] = []
    //    private var skinTestObjects: [CKRecord] = []
    //    private var oralFoodTestObjects: [CKRecord] = []
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
//                    Image(systemName: "square.and.arrow.up.on.square")
//                        .font(.caption)
//                        .fontWeight(.bold)
                    Text("完了") // Save
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
        
        newBloodTests.forEach {
            let ckRecordZoneID = CKRecordZone(zoneName: "Profile")
            let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
            let myRecord = CKRecord(recordType: "BloodTest", recordID: ckRecordID)
            
            myRecord["bloodTestDate"] = $0.bloodTestDate
            myRecord["bloodTestLevel"] = $0.bloodTestLevel
            myRecord["bloodTestGrade"] = $0.bloodTestGrade.rawValue
            
            let reference = CKRecord.Reference(recordID: mediacalTest.allergen.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            save(record: myRecord)
        }
        newSkinTests.forEach {
            let ckRecordZoneID = CKRecordZone(zoneName: "Profile")
            let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
            let myRecord = CKRecord(recordType: "SkinTest", recordID: ckRecordID)
            
            myRecord["skinTestDate"] = $0.skinTestDate
            myRecord["SkinTestResultValue"] = $0.SkinTestResultValue
            myRecord["SkinTestResult"] = $0.SkinTestResult
            
            let reference = CKRecord.Reference(recordID: mediacalTest.allergen.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            save(record: myRecord)
        }
        neworalTests.forEach {
            let ckRecordZoneID = CKRecordZone(zoneName: "Profile")
            let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
            let myRecord = CKRecord(recordType: "OralFoodChallenge", recordID: ckRecordID)
            
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
            myRecord["SkinTestResultValue"] = $0.SkinTestResultValue
            myRecord["SkinTestResult"] = $0.SkinTestResult
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
    var body: some View {
        VStack {
            List {
                Text("昇順：「検査日」") // Order: Test Date Descending
                    .foregroundColor(.secondary)
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
            Button(action: {
                bloodTests.append(BloodTest())
            }) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("新しい記録") // Add New
                }
            }
            .padding(.bottom)
        }
    }
}

//MARK: - View: Skin Test Section
struct SkinTestSection: View {
    @Binding var skinTests: [SkinTest]
    @Binding var deleteIDs: [CKRecord.ID]
    
    var body: some View {
        VStack {
            List {
                Text("昇順：「検査日」") // Order: Test Date Descending
                    .foregroundColor(.secondary)
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
                skinTests.append(SkinTest())
            }) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("新しい記録") // Add New
                }
            }
            .padding(.bottom)
        }
    }
}

//MARK: - View: OFC Section
struct OralFoodChallengeSection: View {
    @Binding var oralFoodChallenges: [OralFoodChallenge]
    @Binding var deleteIDs: [CKRecord.ID]
    
    var body: some View {
        VStack {
            List {
                Text("昇順：「検査日」") // Order: Test Date Descending
                    .foregroundColor(.secondary)
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
                oralFoodChallenges.append(OralFoodChallenge())
            }) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("新しい記録") // Add New
                }
            }
            .padding(.bottom)
        }
    }
}

//MARK: - Form View: Blood Test

struct BloodTestFormView: View {
    @Binding var bloodTest: BloodTest
    
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
                TextField("0.0", text: $bloodTest.bloodTestLevel)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            VStack(alignment: .leading) {
                Picker("IgEクラス", selection: $bloodTest.bloodTestGrade) { // BloodTest Test Grade
                    ForEach(BloodTestGrade.allCases, id: \.self) { grade in
                        Text(grade.rawValue).tag(grade)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

//MARK: - Form View: Skin Test

struct SkinTestFormView: View {
    @Binding var skinTest: SkinTest
    
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
                    TextField("0.0", text: $skinTest.SkinTestResultValue)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            HStack {
                Text("陽性有無") // SkinTest Result
                Spacer()
                Toggle("", isOn: $skinTest.SkinTestResult)
                    .toggleStyle(SwitchToggleStyle())
            }
        }
    }
}

//MARK: - Form View: OFC
struct OralFoodChallengeFormView: View {
    @Binding var oralFoodChallenge: OralFoodChallenge
    
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
                TextField("0.0", text: $oralFoodChallenge.oralFoodChallengeQuantity)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
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
