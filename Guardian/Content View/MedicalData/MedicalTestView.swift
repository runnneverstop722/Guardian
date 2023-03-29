//
//  MedicalTestView.swift
//  Guardian
//
//  Created by Teff on 2023/03/23.
//

import SwiftUI

struct BloodTest: Identifiable {
    let id = UUID()
    var bloodTestDate: Date = Date()
    var bloodTestLevel: String = ""
    var bloodTestGrade: BloodTestGrade = .negative
}

struct SkinTest: Identifiable {
    let id = UUID()
    var skinTestDate: Date = Date()
    var SkinTestResultValue: String = ""
    var SkinTestResult: Bool = false
}

struct OralFoodChallenge: Identifiable {
    let id = UUID()
    var oralFoodChallengeDate: Date = Date()
    var oralFoodChallengeQuantity: String = ""
    var oralFoodChallengeResult: Bool = false
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
    
    @Environment(\.presentationMode) var presentationMode
    
    
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
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct BloodTestSection: View {
    @Binding var bloodTests: [BloodTest]
    
    var body: some View {
        VStack {
            List {
                ForEach(bloodTests.indices, id: \.self) { index in
                    BloodTestFormView(bloodTest: $bloodTests[index])
                }
                .onDelete(perform: { indexSet in
                    bloodTests.remove(atOffsets: indexSet)
                })
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


struct MedicalTestView_Previews: PreviewProvider {
    static var previews: some View {
        MedicalTestView()
    }
}
