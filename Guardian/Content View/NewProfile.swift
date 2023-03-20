//
//  NewProfile.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI
import PhotosUI
import CloudKit

struct NewProfile: View {
   
    @StateObject var vm = ProfileModel()
    
    @State private var showingAlert = false
    @Environment(\.dismiss) private var dismiss
   
    var body: some View {
        NavigationView {
            Form(content: {
                Section(header: Text("ユーザー")) {
                    VStack {
                        Section {
                            HStack {
                                Spacer()
                                EditableCircularProfileImage(viewModel: vm)
                                Spacer()
                            }
                        }
                        .listRowBackground(Color.clear)
                        #if !os(macOS)
                        .padding([.top], 10)
                        #endif
                        
                        Section {
                            TextField("姓",
                                      text: $vm.lastName,
                                      prompt: Text("姓"))
                            Divider()
                            TextField("名",
                                      text: $vm.firstName,
                                      prompt: Text("名"))
                            Divider()
                            Spacer()
                            Picker("Gender", selection: $vm.gender) {
                                ForEach(ProfileModel.Gender.allCases) { gender in
                                    Text(gender.rawValue.capitalized).tag(gender)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            Spacer()
                            DatePicker("生年月日",
                                       selection: $vm.birthDate,
                                       displayedComponents: [.date])
                            .environment(\.locale, Locale(identifier: "ja_JP"))
                            //.environment(\.calendar, Calendar(identifier: .japanese))
                            .foregroundColor(Color(uiColor: .placeholderText))
                            
                        }
                        .fontWeight(.bold)
                    }
                }
                
                Section(header: Text("通院先")) {
                    TextField("病院名",
                              text: $vm.hospitalName,
                              prompt: Text("病院名"))
                    TextField("担当医",
                              text: $vm.allergist,
                              prompt: Text("担当医"))
                    TextField("担当医連絡先",
                              text: $vm.allergistContactInfo,
                              prompt: Text("担当医連絡先"))
                    .keyboardType(.phonePad)
                    
                }
                .fontWeight(.bold)
                
                Section {
                    Button(action: {
                        vm.addButtonPressed()
                        showingAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("登録")
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("ユーザーを登録しました"),
                              message: Text(""), dismissButton: .default(Text("閉じる"), action: {
                            dismiss()
                        }))
                    }
                }
            })
            .navigationTitle("ユーザー登録")
        }
    }
    
    struct NewProfile_Previews: PreviewProvider {
        static var previews: some View {
            NavigationStack {
                NewProfile()
            }
        }
    }
}
