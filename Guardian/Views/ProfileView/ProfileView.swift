//  ProfileView.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI
import PhotosUI
import CloudKit
import UIKit

enum FormField1 {
    case lastName
    case firstName
}
enum FormField2 {
    case hospitalName
    case allergist
    case allergistContactInfo
}

struct ProfileView: View {
    @StateObject var profileModel: ProfileModel
    @State private var showingAddAllergen = false
    @State private var showingRemoveAlert = false
    @State private var isUpdate = false
    @State private var activeAlert: ActiveAlert?
    @FocusState private var focusedField1: FormField1?
    @FocusState private var focusedField2: FormField2?
    @Environment(\.presentationMode) var presentationMode
    @State private var isLastNameEmpty = true
    @State private var isFirstNameEmpty = true
    
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
        _isLastNameEmpty = State(initialValue: profile["lastName"] == nil || (profile["lastName"] as? String)?.isEmpty == true)
        _isFirstNameEmpty = State(initialValue: profile["firstName"] == nil || (profile["firstName"] as? String)?.isEmpty == true)
    }
    private var formValidation: FormValidationProfile {
        FormValidationProfile(isLastNameEmpty: isLastNameEmpty, isFirstNameEmpty: isFirstNameEmpty, isAllergensEmpty: profileModel.allergens.isEmpty)
    }
    
    //MARK: - Body
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ユーザー").font(.headline)) {
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
                            TextField("姓", text: $profileModel.lastName)
                                .textFieldStyle(RequiredFieldStyle(isEmpty: isLastNameEmpty))
                                .focused($focusedField1, equals: .lastName)
                                .onChange(of: profileModel.lastName) { _ in
                                    isLastNameEmpty = profileModel.lastName.isEmpty
                                }
                            Divider()
                            TextField("名", text: $profileModel.firstName)
                                .textFieldStyle(RequiredFieldStyle(isEmpty: isFirstNameEmpty))
                                .focused($focusedField1, equals: .firstName)
                                .onChange(of: profileModel.firstName) { _ in
                                    isFirstNameEmpty = profileModel.firstName.isEmpty
                                }
                            
                            Divider()
                            Picker("Gender", selection: $profileModel.gender) {
                                ForEach(ProfileModel.Gender.allCases) { gender in
                                    Text(gender.rawValue.capitalized).tag(gender)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            DatePicker("生年月日",
                                       selection: $profileModel.birthDate,
                                       displayedComponents: [.date])
                            .foregroundColor(Color(uiColor: .placeholderText))
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                        }
                        .fontWeight(.bold)
                    }
                }
                Section(header: Text("医療機関").font(.headline)) {
                    TextField("病院名", text: $profileModel.hospitalName)
                        .submitLabel(.next)
                        .focused($focusedField2, equals: .hospitalName)
                    
                    TextField("担当医", text: $profileModel.allergist)
                        .submitLabel(.next)
                        .focused($focusedField2, equals: .allergist)
                    
                    TextField("担当医連絡先", text: $profileModel.allergistContactInfo)
                        .submitLabel(.done)
                        .focused($focusedField2, equals: .allergistContactInfo)
                }
                .fontWeight(.bold)
                
                Section(header: Text("食べないようにしている食物").font(.headline)) {
                    ForEach(profileModel.allergens, id: \.self) { allergen in
                        Text(allergen)
                    }
                    .onDelete(perform: deleteAllergen)
                    
                    Button(action: {
                        showingAddAllergen.toggle()
                    }) {
                        ZStack {
                            RowBackground(isEmpty: profileModel.allergens.isEmpty)
                            HStack {
                                Symbols.allergens
                                Text("アレルゲンを選択")
                            }
                        }
                    }
                    .sheet(isPresented: $showingAddAllergen) {
                        AddAllergenView(allergenOptions: allergenOptions, selectedAllergens: $profileModel.allergens, selectedItems: Set($profileModel.allergens.wrappedValue))
                    }
                }
            }
            .keyboardDismissGesture()
            .onSubmit {
                switch focusedField1 {
                case .lastName:
                    focusedField1 = .firstName
                default:
                    focusedField1 = nil
                }
                
                switch focusedField2 {
                case .hospitalName:
                    focusedField2 = .allergist
                case .allergist:
                    focusedField2 = .allergistContactInfo
                default:
                    focusedField2 = nil
                }
            }
            .navigationTitle("プロフィール")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let validation = formValidation
                        if validation.validateForm() {
                            profileModel.addButtonPressed()
                            activeAlert = .saveConfirmation
                        } else {
                            activeAlert = .emptyValidation
                        }
                    } label: {
                        Symbols.done
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
                            return Alert(title: Text("入力されてない項目があります。"),
                                         message: Text(formValidation.getEmptyFieldsMessage()),
                                         dismissButton: .default(Text("閉じる")))
                        case .saveError:
                            return Alert(title: Text("保存できませんでした。"),
                                         message: Text("もう一度試してください。"),
                                         dismissButton: .default(Text("閉じる")))
                        }
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
            Image(systemName: "arrow.uturn.backward")
        })
    }
    private func deleteAllergen(at offsets: IndexSet) {
        profileModel.allergens.remove(atOffsets: offsets)
    }
}
