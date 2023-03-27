//
//  MedicalDataView.swift
//  Guardian
//
//  Created by Teff on 2023/03/23.
//

import SwiftUI

struct BloodTest: Identifiable {
    let id = UUID()
    var date: Date = Date()
    var level: String = ""
    var grade: BloodTestGrade = .negative
}

struct SkinTest: Identifiable {
    let id = UUID()
    var date: Date = Date()
    var result: String = ""
    var positive: Bool = false
}

struct OralFoodChallenge: Identifiable {
    let id = UUID()
    var date: Date = Date()
    var quantity: String = ""
    var result: Bool = false
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


struct MedicalDataView: View {
    @State private var selectedTestIndex = 0
    @State private var allergenName = "AllergenShrimp"
    
    @State private var bloodTests: [BloodTest] = []
    @State private var skinTests: [SkinTest] = []
    @State private var oralFoodChallenges: [OralFoodChallenge] = []
    
    @Environment(\.presentationMode) var presentationMode
    
    
    var totalNumberOfMedicalData: String {
        return "\(allergenName)TotalNumberOfMedicalData: \(bloodTests.count + skinTests.count + oralFoodChallenges.count)"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text(allergenName)
                    .font(.largeTitle)
                    .padding()
                
                Picker(selection: $selectedTestIndex, label: Text("Test Type")) {
                    Text("Blood Test").tag(0)
                    Text("Skin Test").tag(1)
                    Text("Oral Food Challenge").tag(2)
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
            .navigationTitle("Medical Data")
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
                Text("+Add Blood Test")
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
                Text("+Add Skin Test")
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
                Text("+Add Oral Food Challenge")
            }
            .padding(.bottom)
        }
    }
}

struct BloodTestFormView: View {
    @Binding var bloodTest: BloodTest
    
    private var textFieldBinding: Binding<String> {
            Binding(
                get: { bloodTest.grade.rawValue },
                set: { newValue in
                    if let newGrade = BloodTestGrade(rawValue: newValue) {
                        bloodTest.grade = newGrade
                    }
                }
            )
        }
    
    var body: some View {
        VStack {
            HStack {
                Text("Test Date:")
                Spacer()
                DatePicker("", selection: $bloodTest.date, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
            }
            
            HStack {
                Text("IgEレベル(UA/mL):")
                Spacer()
                TextField("0.0", text: $bloodTest.level)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            VStack(alignment: .leading) {
                Picker("IgEクラス:", selection: $bloodTest.grade) {
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
                DatePicker("", selection: $skinTest.date, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
            }
            
            HStack {
                Text("結果(mm):")
                Spacer()
                HStack {
                    Spacer()
                    TextField("0.0", text: $skinTest.result)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            HStack {
                Text("陽性?:")
                Spacer()
                Toggle("", isOn: $skinTest.positive)
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
                DatePicker("", selection: $oralFoodChallenge.date, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
            }
            
            HStack {
                Text("食べた量(mm):")
                Spacer()
                TextField("0.0", text: $oralFoodChallenge.quantity)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("症状あり:")
                Spacer()
                Toggle("", isOn: $oralFoodChallenge.result)
                    .toggleStyle(SwitchToggleStyle())
            }
        }
    }
}


struct MedicalDataView_Previews: PreviewProvider {
    static var previews: some View {
        MedicalDataView()
    }
}
