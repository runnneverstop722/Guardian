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
    @State private var isUpdate = false
    
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
    case grade1 = "1"
    case grade2 = "2"
    case grade3 = "3"
    case grade4 = "4"
    case grade5 = "5"
    case grade6 = "6"
}

//MARK: - Struct: Skin Test

struct SkinTest: Identifiable {
    let id = UUID()
    var skinTestDate: Date = Date()
    var SkinTestResultValue: String = ""
    var SkinTestResult: Bool = false
    var record: CKRecord?
    @State private var isUpdate = false
    
    init?(record: CKRecord) {
        
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
    @State private var isUpdate = false
    
    init?(record: CKRecord) {
        
    }
    init() {
        
    }
}

//MARK: - MedicalTestView

struct MedicalTestView: View {
    @StateObject var medicalTestModel: MedicalTestModel
    
    @State private var selectedTestIndex = 0
//    @State private var allergenName = "AllergenShrimp"
    
    @Environment(\.presentationMode) var presentationMode
    
    var allergenNameInMedicalTest: String = "Unknown Allergen"
    
    let allergen: CKRecord
    let existingMedicalTestData = NotificationCenter.default.publisher(for: Notification.Name("existingMedicalTestData"))
    
    init(allergen: CKRecord) {
        self.allergen = allergen
        allergenNameInMedicalTest = allergen["allergen"] as? String ?? ""
        _medicalTestModel = StateObject(wrappedValue: MedicalTestModel(record: allergen))
    }
    var totalNumberOfBloodTest: String {
        return "\(allergenNameInMedicalTest)TotalNumberOfBloodTest: \(medicalTestModel.bloodTestInfo.count)"
    }
    var totalNumberOSkinest: String {
        return "\(allergenNameInMedicalTest)totalNumberOSkinest: \(medicalTestModel.skinTestInfo.count)"
    }
    var totalNumberOfOFC: String {
        return "\(allergenNameInMedicalTest)totalNumberOfOFC: \(medicalTestModel.OFCInfo.count)"
    }
    var totalNumberOfMedicalTest: String {
        return "\(allergenNameInMedicalTest)TotalNumberOfMedicalTest: \(medicalTestModel.bloodTestInfo.count + medicalTestModel.skinTestInfo.count + medicalTestModel.OFCInfo.count)"
    }
    
    //MARK: - Body View
    
    var body: some View {
        NavigationView {
            VStack {
                Text(allergenNameInMedicalTest)
                    .font(.largeTitle)
                    .padding()
                Picker(selection: $selectedTestIndex, label: Text("Test Category")) {
                    Text("Blood Test").tag(0)
                    Text("Skin Test").tag(1)
                    Text("Oral Food Challenge").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                VStack {
                    if selectedTestIndex == 0 {
                        BloodTestSection(bloodTests: $medicalTestModel.bloodTestInfo)
                    } else if selectedTestIndex == 1 {
                        SkinTestSection(skinTests: $medicalTestModel.skinTestInfo)
                    } else {
                        OralFoodChallengeSection(oralFoodChallenges: $medicalTestModel.OFCInfo)
                    }
                }
                .animation(.default, value: selectedTestIndex)
            }
            .navigationTitle("Medical Test")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        medicalTestModel.saveData()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
}

//MARK: - View: Blood Test Section
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

//MARK: - View: Skin Test Section
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

//MARK: - View: OFC Section
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

//MARK: - Form View: Skin Test

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

//MARK: - Form View: OFC
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
