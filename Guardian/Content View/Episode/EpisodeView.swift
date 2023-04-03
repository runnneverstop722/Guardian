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
        NavigationView {
            Form {
                DatePicker("日付", selection: $episodeModel.episodeDate, displayedComponents: .date)

                Toggle("初症状ですか？", isOn: $episodeModel.firstKnownExposure)

                Toggle("病院で受診しましたか？", isOn: $episodeModel.wentToHospital)

                Section(header: Text("どのような形でアレルゲンに触れましたか？（複数選択可）")) {
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

                Section(header: Text("どのような症状が出ましたか?")) {
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

                Section(header: Text("アレルゲンに触れてからどれほど時間が経ってから症状が現れましたか?")) {
                    Picker("Lead Time", selection: $episodeModel.leadTimeToSymptoms) {
                        ForEach(episodeModel.leadTimeToSymptomsOptions, id: \.self) {
                            Text($0)
                        }
                    }
                }

                Section(header: Text("どんな対応を取りましたか?（複数選択可）")) {
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
                        TextField("その他の対応処置", text: $episodeModel.otherTreatment)
                    }
                }
                Section(header: Text("添付写真")) {
                    Button(action: {
                            isPickerPresented = true
                        }) {
                            Text("Select Images")
                        }
                        .sheet(isPresented: $isPickerPresented) {
                            PhotoPicker(selectedImages: $episodeModel.episodeImages)
                        }

                        // Add this line to print the count of episode images
                        Text("Selected Images: \(episodeModel.episodeImages.count)")
                        .font(.headline)


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
//                            .padding(.top, 10)
//                            Spacer()
                        }
//                        .padding()
                    }
                }
                
                if isUpdate {
                    Section {
                        
                        Button(action: {
                            showRemoveAlert.toggle()
                        }) {
                            HStack {
                                Spacer()
                                Text("Remove")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                        }
                        .alert(isPresented: $showRemoveAlert) {
                            Alert(title: Text("Remove this item?"), message: Text("This action cannot be undone."), primaryButton: .destructive(Text("Remove")) {
                                // Handle removal of item
                                episodeModel.deleteRecord(record: episodeModel.record)
                                dismiss.callAsFunction()
                                
                            }, secondaryButton: .cancel())
                        }
                    }
                }
            }
            .navigationBarTitle("Episode")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        episodeModel.addButtonPressed()
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
    private func createAdaptiveColumns() -> [GridItem] {
            let minWidth: CGFloat = 100
            let spacing: CGFloat = 10
            let adaptiveColumns = [
                GridItem(.adaptive(minimum: minWidth, maximum: minWidth), spacing: spacing)
            ]
            return adaptiveColumns
        }
}

//struct Episode_Previews: PreviewProvider {
//    static var previews: some View {
//        EpisodeView()
//    }
//}

