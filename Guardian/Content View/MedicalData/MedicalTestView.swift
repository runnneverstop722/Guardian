//
//  MedicalTestView.swift
//  Guardian
//
//  Created by Teff on 2023/03/23.
//

import SwiftUI
import CloudKit

struct BloodTest: Identifiable {
    let id = UUID()
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

struct SkinTest: Identifiable {
    let id = UUID()
    var skinTestDate: Date = Date()
    var SkinTestResultValue: String = ""
    var SkinTestResult: Bool = false
    var record: CKRecord?
    init?(record: CKRecord) {
        
    }
    init() {
        
    }
}

struct OralFoodChallenge: Identifiable {
    let id = UUID()
    var oralFoodChallengeDate: Date = Date()
    var oralFoodChallengeQuantity: String = ""
    var oralFoodChallengeResult: Bool = false
    var record: CKRecord?
    init?(record: CKRecord) {
        
    }
    init() {
        
    }
}

enum BloodTestGrade: String, CaseIterable {
    case negative = "陰性(~0.35)"
    case grade1 = "1"
    case grade2 = "2"
    case grade3 = "3"
    case grade4 = "4"
    case grade5 = "5"
    case grade6 = "6"
}


struct MedicalTestView: View {
    @State private var selectedTestIndex = 0
    @State private var allergenName = "AllergenShrimp"
    
    @State private var bloodTests: [BloodTest] = []
    @State private var skinTests: [SkinTest] = []
    @State private var oralFoodChallenges: [OralFoodChallenge] = []
//    private var bloodTestObjects: [CKRecord] = []
//    private var skinTestObjects: [CKRecord] = []
//    private var oralFoodTestObjects: [CKRecord] = []
    @Environment(\.presentationMode) var presentationMode
    
    var allergen: CKRecord
    
    init(allergen: CKRecord) {
        self.allergen = allergen
        fetchData()
    }
    
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().privateCloudDatabase.add(operation)
    }
    
    private func fetchData() {
        let reference = CKRecord.Reference(recordID: allergen.recordID, action: .deleteSelf)
        let predicate = NSPredicate(format: "allergen == %@", reference)
        
        let bloodQuery = CKQuery(recordType: "BloodTest", predicate: predicate)
        bloodQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let bloodQueryOperation = CKQueryOperation(query: bloodQuery)

        bloodQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = BloodTest(record: returnedRecord) {
                    self.bloodTests.append(object)
                }
            }
        }
        bloodQueryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED Allergens queryResultBlock")
        }
        addOperation(operation: bloodQueryOperation)
        
        
        let skinQuery = CKQuery(recordType: "SkinTest", predicate: predicate)
        skinQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let skinQueryOperation = CKQueryOperation(query: skinQuery)

        skinQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = SkinTest(record: returnedRecord) {
                    self.skinTests.append(object)
                }
            }
        }
        skinQueryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED Allergens queryResultBlock")
        }
        let oralQuery = CKQuery(recordType: "OralFoodChallenge", predicate: predicate)
        oralQuery.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let oralQueryOperation = CKQueryOperation(query: oralQuery)

        oralQueryOperation.recordFetchedBlock = { (returnedRecord) in
            DispatchQueue.main.async {
                if let object = OralFoodChallenge(record: returnedRecord) {
                    self.oralFoodChallenges.append(object)
                }
            }
        }
        oralQueryOperation.queryCompletionBlock = { (returnedCursor, returnedError) in
            print("RETURNED Allergens queryResultBlock")
        }
        addOperation(operation: skinQueryOperation)
    }
    func fetchSkinTests() {
        
    }
    var totalNumberOfMedicalTest: String {
        return "\(allergenName)TotalNumberOfMedicalTestData: \(bloodTests.count + skinTests.count + oralFoodChallenges.count)"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text(allergenName)
                    .font(.largeTitle)
                    .padding()
                
                Picker(selection: $selectedTestIndex, label: Text("Test Type")) {
                    Text("血液検査").tag(0)
                    Text("皮膚プリックテスト").tag(1)
                    Text("経口負荷試験(OFC)").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                VStack {
                    if selectedTestIndex == 0 {
                        BloodTestSection(bloodTests: $bloodTests)
                    } else if selectedTestIndex == 1 {
                        SkinTestSection(skinTests: $skinTests)
                    } else {
                        OralFoodChallengeSection(oralFoodChallenges: $oralFoodChallenges)
                    }
                }
                .animation(.default, value: selectedTestIndex)
            }
            .navigationTitle("Medical Test")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveData()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    func saveData() {
        updateData()
        
        let newBloodTests = bloodTests.filter { $0.record == nil }
        let newSkinTests = skinTests.filter { $0.record == nil }
        let neworalTests = oralFoodChallenges.filter { $0.record == nil }
        
        newBloodTests.forEach {
            let ckRecordZoneID = CKRecordZone(zoneName: "Profile")
            let ckRecordID = CKRecord.ID(zoneID: ckRecordZoneID.zoneID)
            let myRecord = CKRecord(recordType: "BloodTest", recordID: ckRecordID)
            
            myRecord["bloodTestDate"] = $0.bloodTestDate
            myRecord["bloodTestLevel"] = $0.bloodTestLevel
            myRecord["bloodTestGrade"] = $0.bloodTestGrade.rawValue
            
            let reference = CKRecord.Reference(recordID: allergen.recordID, action: .deleteSelf)
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
            
            let reference = CKRecord.Reference(recordID: allergen.recordID, action: .deleteSelf)
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
            
            let reference = CKRecord.Reference(recordID: allergen.recordID, action: .deleteSelf)
            myRecord["allergen"] = reference as CKRecordValue
            save(record: myRecord)
        }
    }
    
    func updateData() {
        
    }
    
    private func save(record: CKRecord) {
        CKContainer.default().privateCloudDatabase.save(record) { returnedRecord, returnedError in
            print("Record: \(String(describing: returnedRecord))")
            print("Error: \(String(describing: returnedError))")
        }
    }
}

struct BloodTestSection: View {
    @Binding var bloodTests: [BloodTest]
    
    var body: some View {
        VStack {
            
            List {
                ForEach($bloodTests) { test in
                    BloodTestFormView(bloodTest: test)
                }
            }
            
            Button(action: {
                bloodTests.append(BloodTest())
            }) {
                Text("+新しい記録")
            }
            .padding(.bottom)
        }
    }
}

struct SkinTestSection: View {
    @Binding var skinTests: [SkinTest]
    
    var body: some View {
        VStack {
            List {
                ForEach(skinTests.indices, id: \.self) { index in
                    SkinTestFormView(skinTest: $skinTests[index])
                }
                .onDelete(perform: { indexSet in
                    skinTests.remove(atOffsets: indexSet)
                })
            }
            
            Button(action: {
                skinTests.append(SkinTest())
            }) {
                Text("+新しい記録")
            }
            .padding(.bottom)
        }
    }
}

struct OralFoodChallengeSection: View {
    @Binding var oralFoodChallenges: [OralFoodChallenge]
    
    var body: some View {
        VStack {
            List {
                ForEach(oralFoodChallenges.indices, id: \.self) { index in
                    OralFoodChallengeFormView(oralFoodChallenge: $oralFoodChallenges[index])
                }
                .onDelete(perform: { indexSet in
                    oralFoodChallenges.remove(atOffsets: indexSet)
                })
            }
            
            Button(action: {
                oralFoodChallenges.append(OralFoodChallenge())
            }) {
                Text("+新しい記録")
            }
            .padding(.bottom)
        }
    }
}

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
                Text("日付:")
                Spacer()
                DatePicker("", selection: $bloodTest.bloodTestDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
            }
            
            HStack {
                Text("IgEレベル(UA/mL):")
                Spacer()
                TextField("0.0", text: $bloodTest.bloodTestLevel)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            VStack(alignment: .leading) {
                Picker("IgEクラス:", selection: $bloodTest.bloodTestGrade) {
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

struct SkinTestFormView: View {
    @Binding var skinTest: SkinTest
    
    var body: some View {
        VStack {
            HStack {
                Text("日付:")
                Spacer()
                DatePicker("", selection: $skinTest.skinTestDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
            }
            
            HStack {
                Text("結果(mm):")
                Spacer()
                HStack {
                    Spacer()
                    TextField("0.0", text: $skinTest.SkinTestResultValue)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            HStack {
                Text("陽性?:")
                Spacer()
                Toggle("", isOn: $skinTest.SkinTestResult)
                    .toggleStyle(SwitchToggleStyle())
            }
        }
    }
}

struct OralFoodChallengeFormView: View {
    @Binding var oralFoodChallenge: OralFoodChallenge
    
    
    var body: some View {
        VStack {
            HStack {
                Text("日付:")
                Spacer()
                DatePicker("", selection: $oralFoodChallenge.oralFoodChallengeDate, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
            }
            
            HStack {
                Text("食べた量(mm):")
                Spacer()
                TextField("0.0", text: $oralFoodChallenge.oralFoodChallengeQuantity)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("症状あり:")
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
