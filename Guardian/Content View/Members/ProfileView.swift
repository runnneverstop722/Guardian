//  ProfileView.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI
import PhotosUI
import CloudKit

struct ProfileView: View {
    @StateObject var profileModel: ProfileModel
    @State private var showingAddAllergen = false
    @State private var showingAlert = false
    @State private var isUpdate = false
    @Environment(\.dismiss) private var dismiss
    
    var profile: CKRecord?
    private let diagnosisOptions = ["即時型IgE抗体アレルギー", "遅延型IgG抗体アレルギー", "アレルギー性腸炎", "好酸球性消化管疾患", "食物たんぱく誘発胃腸症（消化管アレルギー）"]
    private let allergenOptions = ["えび", "かに", "小麦", "そば", "卵", "乳", "落花生(ピーナッツ)", "アーモンド", "あわび", "いか", "いくら", "オレンジ", "カシューナッツ", "キウイフルーツ", "牛肉", "くるみ", "ごま", "さけ", "さば", "大豆", "鶏肉", "バナナ", "豚肉", "まつたけ", "もも", "やまいも", "りんご", "ゼラチン"]
    
    init() {
        _profileModel = StateObject(wrappedValue: ProfileModel())
    }
    
    init(profile: CKRecord) {
        self.profile = profile
        _profileModel = StateObject(wrappedValue: ProfileModel(profile: profile))
    }
    
    var body: some View {
        NavigationView {
            Form(content: {
                Section(header: Text("ユーザー")) {
                    VStack {
                        Section {
                            HStack {
                                Spacer()
                                EditableCircularProfileImage(viewModel: profileModel)
                                Spacer()
                            }
                        }
                        .listRowBackground(Color.clear)
#if !os(macOS)
                        .padding([.top], 10)
#endif
                        
                        Section {
                            TextField("姓",
                                      text: $profileModel.lastName,
                                      prompt: Text("姓"))
                            Divider()
                            TextField("名",
                                      text: $profileModel.firstName,
                                      prompt: Text("名"))
                            Divider()
                            Spacer()
                            Picker("Gender", selection: $profileModel.gender) {
                                ForEach(ProfileModel.Gender.allCases) { gender in
                                    Text(gender.rawValue.capitalized).tag(gender)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            Spacer()
                            DatePicker("生年月日",
                                       selection: $profileModel.birthDate,
                                       displayedComponents: [.date])
//                            .environment(\.locale, Locale(identifier: "ja_JP"))
                            //.environment(\.calendar, Calendar(identifier: .japanese))
                            .foregroundColor(Color(uiColor: .placeholderText))
                        }
                        .fontWeight(.bold)
                    }
                }
                
                Section(header: Text("通院先")) {
                    TextField("Hospital",
                              text: $profileModel.hospitalName,
                              prompt: Text("病院名"))
                    TextField("Allergist",
                              text: $profileModel.allergist,
                              prompt: Text("担当医"))
                    TextField("Allergist's Contact Info",
                              text: $profileModel.allergistContactInfo,
                              prompt: Text("担当医連絡先"))
                    .keyboardType(.phonePad)
                }
                .fontWeight(.bold)
                
                // Added this selector in ProfileView
                Section(header: Text("Allergens")) {
                    ForEach(profileModel.allergens, id: \.self) { allergen in
                        Text(allergen)
                    }
                    .onDelete(perform: deleteAllergen)
                    Button("Add Allergen") {
                        showingAddAllergen.toggle()
                    }
                    .sheet(isPresented: $showingAddAllergen) {
                        AddAllergenView(allergenOptions: allergenOptions, selectedAllergens: $profileModel.allergens)
                    }
                }
            })
            .navigationTitle("Profile")
            .toolbar {
                if isUpdate {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            profileModel.addButtonPressed()
                            showingAlert = true
                        }
                        .alert(isPresented: $showingAlert) {
                            Alert(title: Text("データが保存されました。"),
                                  message: Text(""), dismissButton: .default(Text("Close"), action: {
                                dismiss()
                            }))
                        }
                    }
                }
            }
        }
    }
    private func deleteAllergen(at offsets: IndexSet) {
        profileModel.allergens.remove(atOffsets: offsets)
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
