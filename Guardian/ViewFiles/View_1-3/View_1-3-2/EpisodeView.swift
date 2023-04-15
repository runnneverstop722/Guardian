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

enum EpisodeFormField {
    case intakeAmount, otherTreatment
}
struct EpisodeView: View {
    @StateObject var episodeModel: EpisodeModel
    @State private var isPickerPresented: Bool = false
    @State private var selectedImages: [Image] = []
    @State private var showingAlert = false
    @State private var isUpdate = false
    @State private var showRemoveAlert = false
    @FocusState private var episodeFocusedField: EpisodeFormField?
    @Environment(\.dismiss) private var dismiss
    
    let allergen: CKRecord
    init(allergen: CKRecord, episode: CKRecord) {
        self.allergen = allergen
        _episodeModel = StateObject(wrappedValue: EpisodeModel(allergen: allergen, episode: episode))
        _isUpdate = State(wrappedValue: true)
    }
    init(record: CKRecord) {
        self.allergen = record
        _episodeModel = StateObject(wrappedValue: EpisodeModel(record: record))
    }
    
    var body: some View {
        Form {
            DatePicker("日付", selection: $episodeModel.episodeDate, displayedComponents: .date)
                .environment(\.locale, Locale(identifier: "ja_JP"))
            Toggle("初症状だった", isOn: $episodeModel.firstKnownExposure)
            Toggle("病院で受診した", isOn: $episodeModel.wentToHospital)
            
            
            Section(header: Text("接触タイプ（複数選択可）")
                .font(.headline),
                    footer: Text("※摂取の場合、摂取量も記録しましょう。")
                .font(.footnote)
                .foregroundColor(.secondary)) {
                    ForEach(episodeModel.typeOfExposureOptions, id: \.self) { typeOfExposureOption in
                        Button(action: {
                            if let index = episodeModel.typeOfExposure.firstIndex(of: typeOfExposureOption) {
                                episodeModel.typeOfExposure.remove(at: index)
                            } else {
                                episodeModel.typeOfExposure.append(typeOfExposureOption)
                            }
                        }) {
                            HStack {
                                Text(typeOfExposureOption)
                                Spacer()
                                if episodeModel.typeOfExposure.contains(typeOfExposureOption) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    if episodeModel.typeOfExposure.contains("摂取") {
                        TextField("摂取量はどれほどですか？ 例)卵黄一口", text: $episodeModel.intakeAmount)
                            .submitLabel(.done)
                            .focused($episodeFocusedField, equals: .intakeAmount)
                    }
                }
            
            Section(header: Text("現れた症状（複数選択可）")
                .font(.headline)) {
                    ForEach(episodeModel.symptomCategories, id: \.self) { category in
                        NavigationLink(destination: SelectSymptoms(category: category, selectedSymptoms: $episodeModel.symptoms)) {
                            HStack {
                                Text(category)
                                Spacer()
                                Text("\(episodeModel.symptoms.filter { $0.hasPrefix(category) }.count) 件")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onReceive(episodeModel.$symptoms, perform: { _ in
                        episodeModel.judgeSeverity()
                    })
                }
            
            Section(
                header: Text("重症度評価(自動表示)")
                    .font(.headline),
                footer: Text("※参考:\n ・学校における⾷物アレルギー対応ガイドライン\n  (⼤阪府医師会 学校医部会)\n ・⽇本アレルギー学会アナフィラキシーガイドライン\n  (食物アレルギー研究会)\n・アレルギー症状の重症度評価と対応マニュアル\n  (国立病院機構相模原病院 小児科)")) {
                    HStack {
                        Spacer()
                        Text(episodeModel.displaySeverity())
                            .font(.title3)
                            .foregroundColor(episodeModel.displaySeverity().isEmpty ? .primary : .secondary)
                        Spacer()
                    }
                }
            
            Section(header: Text("アレルゲンと接触から発症まで")
                .font(.headline)) {
                    Picker("経過時間", selection: $episodeModel.leadTimeToSymptoms) {
                        ForEach(episodeModel.leadTimeToSymptomsOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    Toggle("運動後だった", isOn: $episodeModel.didExercise)
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
                            .submitLabel(.done)
                            .focused($episodeFocusedField, equals: .otherTreatment)
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
                        EpisodePhotoPicker(selectedImages: $episodeModel.episodeImages)
                    }
                    
                    // Display the selected image thumbnails
                    ScrollView(.horizontal) {
                        VStack(alignment: .leading) {
                            HStack {
                                ForEach(episodeModel.episodeImages, id: \.data) { episodeImage in
                                    if let uiImage = UIImage(data: episodeImage.data) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                            Button {
                                                episodeModel.episodeImages.removeAll { $0.id == episodeImage.id }
                                            } label: {
                                                Image(systemName: "x.circle.fill")
                                                    .resizable()
                                                    .foregroundColor(.red)
                                                    .scaledToFit()
                                                    .frame(width: 30, height: 30)
                                                    .clipped()
                                            }
                                        }
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
                        Alert(title: Text("この発症記録を削除しますか？"),
                              message: Text(""), // Delete this episode, are you sure?
                              primaryButton: .destructive(Text("削除")) { // Delete
                            episodeModel.deleteRecord(record: episodeModel.record)
                            dismiss.callAsFunction()
                            
                        }, secondaryButton: .cancel(Text("キャンセル"))) // Cancel
                    }
                }
            }
        }
        .keyboardDismissGesture()
        .navigationBarTitle("発症記録") // Episode
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(role: .none) {
                    showingAlert = true
                } label: {
                    Image(systemName: "checkmark") // Save
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("データが保存されました。"), // The data has successfully saved
                          message: Text(""),
                          dismissButton: .default(Text("閉じる"), action: { // Close
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
