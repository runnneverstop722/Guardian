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
    @State private var showingRemoveAlert = false
    @State private var showingAlert = false
    @State private var isUpdate = false
    @Environment(\.presentationMode) var presentationMode
    
    var profile: CKRecord?
    private let diagnosisOptions = ["即時型IgE抗体アレルギー", "遅延型IgG抗体アレルギー", "アレルギー性腸炎", "好酸球性消化管疾患", "食物たんぱく誘発胃腸症（消化管アレルギー）"]
    private let allergenOptions = ["えび", "かに", "小麦", "そば", "卵", "乳", "落花生(ピーナッツ)", "アーモンド", "あわび", "いか", "いくら", "オレンジ", "カシューナッツ", "キウイフルーツ", "牛肉", "くるみ", "ごま", "さけ", "さば", "大豆", "鶏肉", "バナナ", "豚肉", "まつたけ", "もも", "やまいも", "りんご", "ゼラチン"]
    
    init() {
        _profileModel = StateObject(wrappedValue: ProfileModel())
    }
    
    init(profile: CKRecord) {
        self.profile = profile
        _isUpdate = State(initialValue: true)
        _profileModel = StateObject(wrappedValue: ProfileModel(profile: profile))
    }
    
    var body: some View {
        NavigationView {
            Form(content: {
                Section(header: Text("ユーザー") // User
                    .font(.headline)) {
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
                            TextField("姓", // Last Name
                                      text: $profileModel.lastName,
                                      prompt: Text("姓")) // Last Name
                            Divider()
                            TextField("名", // First Name
                                      text: $profileModel.firstName,
                                      prompt: Text("名")) // First Name
                            Divider()
                            Spacer()
                            Picker("Gender", selection: $profileModel.gender) {
                                ForEach(ProfileModel.Gender.allCases) { gender in
                                    Text(gender.rawValue.capitalized).tag(gender)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            Spacer()
                            DatePicker("生年月日", // Date of Birth
                                       selection: $profileModel.birthDate,
                                       displayedComponents: [.date])
                            .foregroundColor(Color(uiColor: .placeholderText))
                        }
                        .fontWeight(.bold)
                    }
                }
                
                Section(header: Text("通院先") // Clinical Information
                    .font(.headline)) {
                    TextField("Hospital",
                              text: $profileModel.hospitalName,
                              prompt: Text("病院名")) // Hospital Name
                    TextField("Allergist",
                              text: $profileModel.allergist,
                              prompt: Text("担当医")) // Allergist Name
                    TextField("Allergist's Contact Info",
                              text: $profileModel.allergistContactInfo,
                              prompt: Text("担当医連絡先")) // Allergist's Contact Information
                    .keyboardType(.phonePad)
                }
                .fontWeight(.bold)
                
                // Added this selector in ProfileView
                Section(header: Text("管理するアレルゲン") // Allergens that will be managed
                    .font(.headline)) {
                    ForEach(profileModel.allergens, id: \.self) { allergen in
                        Text(allergen)
                    }
                    .onDelete(perform: deleteAllergen)
                    Button(action: {
                        showingAddAllergen.toggle()
                    }) {
                        HStack {
                            Image(systemName: "allergens")
                            Text("アレルゲンを追加") // Add Allergens
                        }
                    }
                    .sheet(isPresented: $showingAddAllergen) {
                        AddAllergenView(allergenOptions: allergenOptions, selectedAllergens: $profileModel.allergens, selectedItems: Set($profileModel.allergens.wrappedValue))
                    }
                }
            })
            .navigationTitle("プロフィール") // Profile
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button() {
                        profileModel.addButtonPressed()
                        showingAlert = true
                    } label: {
                        Text("完了") // Save
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("データが保存されました。"), // Data has been successfully saved
                              message: Text(""),
                              dismissButton: .default(Text("閉じる"), action: { // Close
                            presentationMode.wrappedValue.dismiss()
                        }))
                    }
                }
            }
            .navigationBarItems(leading: cancelButton)
        }
    }
    private var cancelButton: some View {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("キャンセル") // Cancel
            })
        }
    private func deleteAllergen(at offsets: IndexSet) {
        profileModel.allergens.remove(atOffsets: offsets)
    }
    
}
