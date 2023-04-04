//
//  EpisodeView.swift
//  Guardian
//
//  Created by Teff on 2023/03/22.
//
import SwiftUI
import CloudKit
import PhotosUI
import CoreTransferable

struct EpisodeView: View {
    @StateObject var episodeModel: EpisodeModel
    @State private var isPickerPresented: Bool = false
    @State private var showingSelectSymptoms = false
    @State private var showingSelectLocations = false
    @State private var selectedCategory = []
    @State private var selectedImages: [Image] = []
    @State private var showingAlert = false
    @State private var isUpdate = false
    @State private var showRemoveAlert = false
    @Environment(\.dismiss) private var dismiss

    let allergen: CKRecord
    
//    init(allergen: CKRecord) {
//        self.allergen = allergen
//        _episodeModel = StateObject(wrappedValue: EpisodeModel(record: allergen))
//    }
//    init(allergen: CKRecord) {
//        self.allergen = allergen
//        _episodeModel = StateObject(wrappedValue: EpisodeModel(record: allergen))
//        _episodeModel = StateObject(wrappedValue: EpisodeModel(episode: allergen))
//    }
//
    init(episode: CKRecord) {
        self.allergen = episode
        _episodeModel = StateObject(wrappedValue: EpisodeModel(episode: episode))
        _isUpdate = State(wrappedValue: true)
    }
    
    init(record: CKRecord) {
        self.allergen = record
        _episodeModel = StateObject(wrappedValue: EpisodeModel(record: record))
    }

    
    
    var body: some View {
            Form {
                DatePicker("日付", selection: $episodeModel.episodeDate, displayedComponents: .date)
                Toggle("初症状ですか？", isOn: $episodeModel.firstKnownExposure)
                Toggle("病院で受診しましたか？", isOn: $episodeModel.wentToHospital)

                Section(header: Text("接触タイプ（複数選択可）")
                    .font(.headline)) {
                    ForEach(episodeModel.typeOfExposureOptions, id: \.self) { option in
                        Button(action: {
                            if let index = episodeModel.typeOfExposure.firstIndex(of: option) {
                                episodeModel.typeOfExposure.remove(at: index)
                            } else {
                                episodeModel.typeOfExposure.append(option)
                            }
                        }) {
                            HStack {
                                Text(option)
                                Spacer()
                                if episodeModel.typeOfExposure.contains(option) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Section(header: Text("現れた症状（複数選択可）")
                    .font(.headline)) {
                    ForEach(episodeModel.symptomCategories, id: \.self) { category in
                        NavigationLink(destination: SelectSymptoms(category: category, selectedSymptoms: $episodeModel.symptoms)) {
                            HStack {
                                Text(category)
                                Spacer()
                                Text("\(episodeModel.symptoms.filter { $0.hasPrefix(category) }.count)")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                Section(header: Text("アレルゲンと接触から発症まで")
                    .font(.headline)) {
                    Picker("経過時間", selection: $episodeModel.leadTimeToSymptoms) {
                        ForEach(episodeModel.leadTimeToSymptomsOptions, id: \.self) {
                            Text($0)
                        }
                    }
                }

                Section(header: Text("取った対応（複数選択可）")
                    .font(.headline)) {
                    ForEach(episodeModel.treatmentsOptions, id: \.self) { treatment in
                        Button(action: {
                            if let index = episodeModel.treatments.firstIndex(of: treatment) {
                                episodeModel.treatments.remove(at: index)
                            } else {
                                episodeModel.treatments.append(treatment)
                            }
                        }) {
                            HStack {
                                Text(treatment)
                                Spacer()
                                if episodeModel.treatments.contains(treatment) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    if episodeModel.treatments.contains("その他") {
                        TextField("その他", text: $episodeModel.otherTreatment)
                    }
                }
                Section(header: Text("添付写真")
                    .font(.headline)) { // Picture Attachment
                    Button(action: {
                            isPickerPresented = true
                        }) {
                            HStack{
                                Image(systemName: "photo")
                                Text("写真を選択") // Select Images
                                Spacer()
                                Text("選択中: \(episodeModel.episodeImages.count)") // Selected Items
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .sheet(isPresented: $isPickerPresented) {
                            PhotoPicker(selectedImages: $episodeModel.episodeImages)
                        }

                        // Display the selected image thumbnails
                    ScrollView(.horizontal) {
                        VStack(alignment: .leading) {
                            HStack {
                                ForEach(episodeModel.episodeImages, id: \.data) { episodeImage in
                                    if let data = episodeImage.data, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                    } else {
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                    }
                                }
                            }
                            LazyVGrid(columns: createAdaptiveColumns(), spacing: 10) {
                                ForEach(selectedImages.indices, id: \.self) { index in
                                    selectedImages[index]
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(8)
                                        .shadow(radius: 4)
                                }
                            }
                        }
                    }
                }
                
                if isUpdate {
                    Section {
                        Button(action: {
                            showRemoveAlert.toggle()
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "trash")
                                Text("この発症記録を削除する") // Delete this episode.
                                Spacer()
                            }
                            .foregroundColor(.red)
                        }
                        .alert(isPresented: $showRemoveAlert) {
                            Alert(title: Text("この発症記録を削除します。\nよろしいですか？"),
                                  message: Text(""), // Delete this episode, are you sure?
                                  primaryButton: .destructive(Text("削除")) { // Delete
                                episodeModel.deleteRecord(record: episodeModel.record)
                                dismiss.callAsFunction()
                                
                            }, secondaryButton: .cancel(Text("キャンセル"))) // Cancel
                        }
                    }
                }
            }
            .navigationBarTitle("発症記録")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .none) {
                        showingAlert = true
                    } label: {
                        Text("完了")
                    }
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("データが保存されました。"),
                              message: Text(""),
                              dismissButton: .default(Text("閉じる"), action: {
                            episodeModel.addButtonPressed()
                            dismiss()
                            
                        }))
                    }
                }
            }
    }
    private func createAdaptiveColumns() -> [GridItem] {
            let minWidth: CGFloat = 100
            let spacing: CGFloat = 10
            let adaptiveColumns = [
                GridItem(.adaptive(minimum: minWidth, maximum: minWidth), spacing: spacing)
            ]
            return adaptiveColumns
        }
}
