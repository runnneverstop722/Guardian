//
//  AwarenessView.swift
//  Guardian
//
//  Created by realteff on 2023/03/14.
//  Copyright © 2023 swifteff. All rights reserved.
//

import SwiftUI
import CoreData

class AllergensList: ObservableObject {
    @Published var allergens: [String] = [] {
        didSet {
            // Do something when the allergens array is updated
            print("Updated allergens: \(allergens)")
        }
    }
}

struct AwarenessView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ProfileInfoEntity.creationDate, ascending: true)],
        animation: .default)
    private var profiles: FetchedResults<ProfileInfoEntity>
    @State private var selectedProfile: ProfileInfoEntity?
    @State private var showingShareSheet = false
    @State private var showingActionSheet = false
    @State private var isLoading = true
    @State private var progressMessage: String = ""
    @State private var isGeneratingPDF = false
    @State private var isCancelled = false
    @State private var pdfFileURL: URL?
    @ObservedObject var allergensList = AllergensList()
    @State var didLoad = false
    private func allergensList(profile: ProfileInfoEntity?) -> String {
        if let recordID = profile?.recordID {
            let fetchRequest = AllergenEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "profileID == %@", recordID)
            do {
                let records = try viewContext.fetch(fetchRequest)
                
                return records.compactMap({ $0.allergen }).joined(separator: "、")
            } catch let error as NSError {
                print("Could not fetch from local cache. \(error), \(error.userInfo)")
            }
        }
        return ""
    }
    func loadImageFromURL(urlString: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(urlString)
        do {
            let imageData = try Data(contentsOf: fileURL)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image: \(error)")
        }
        return nil
    }
    func sharePDF(viewContext: NSManagedObjectContext) {
        if let selectedProfile = selectedProfile {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isGeneratingPDF = true
            }
            isCancelled = false
            progressMessage = "PDFファイルを作成中です...\n"
            PersistenceController.shared.exportAllRecordsToPDF(selectedProfile: selectedProfile, viewContext: viewContext) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let pdfFileURL):
                        self.pdfFileURL = pdfFileURL
                        print("PDF File URL: \(pdfFileURL)")
                    case .failure(let error):
                        if let _ = error as? CancellationError {
                            self.isCancelled = true
                        } else {
                            print("Error exporting PDF: \(error)")
                        }
                    }
                    self.isGeneratingPDF = false
                    self.showingShareSheet = true
                }
            }
        }
    }
    
    var body: some View {
        LoadingView(isShowing: $isLoading) {
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                    VStack(spacing: 20) {
                        if profiles.isEmpty {
                            Text("⚠️登録済のプロフィールがありません。")
                                .font(.headline)
                                .foregroundColor(.white)
                                .bold()
                        } else {
                            Picker("Select Profile", selection: $selectedProfile) {
                                ForEach(profiles, id: \.id) { (item: ProfileInfoEntity) in
                                    Text(item.firstName ?? "").tag(item as ProfileInfoEntity?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .foregroundColor(.secondary)
                        }
                        if let selectedProfile = selectedProfile {
                            Image(uiImage: loadImageFromURL(urlString: selectedProfile.profileImageData ?? "") ?? UIImage())
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(.white)
                                .clipShape(Circle())
                                .frame(width: 100, height: 100)
                                .onAppear {
                                    print("Profile Image URL String: \(selectedProfile.profileImageData ?? "No URL String")")
                                }
                            Text("\(selectedProfile.firstName ?? "")")
                                .font(.title)
                                .foregroundColor(.white)
                                .bold()
                            Group {
                                Text("食物アレルギーがあります")
                                    .multilineTextAlignment(.center)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text(allergensList(profile: selectedProfile))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding()
                            }
                            Spacer()
                            Group {
                                Text("アレルゲンの混入がないようにご協力を")
                                Text("宜しくお願い申し上げます。")
                            }.font(.headline).foregroundColor(.white)
                            Spacer()
                            Button(action: {
                                showingShareSheet = true
                                sharePDF(viewContext: viewContext)
                            }, label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    Text("記録を共有する")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 30)
                                .padding(.vertical, 10)
                                .background(Color.black)
                                .cornerRadius(8)
                            })
                            .sheet(isPresented: $showingShareSheet) {
                                if isGeneratingPDF {
                                    VStack {
                                        ProgressView(progressMessage)
                                            .progressViewStyle(CircularProgressViewStyle())
                                        Button("キャンセル", action: {
                                            PersistenceController.shared.cancelPDFGeneration()
                                            isGeneratingPDF = false
                                        })
                                    }
                                } else if let pdfURL = pdfFileURL {
                                    ShareSheet(activityItems: [pdfURL])
                                } else if isCancelled {
                                    Text("PDFファイルの作成がキャンセルされました。")
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                    .navigationBarTitle("Awareness")
                    .navigationBarItems(trailing: Button(action: {
                        print("Button pressed")
                    }) {
                        Image(systemName: "plus")
                    })
                    .onAppear() {
                        DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                            if !didLoad {
                                didLoad = true
                                selectedProfile = profiles.first
                                isLoading = false
                            }
                        }
                    }
                    .onChange(of: selectedProfile?.managedObjectContext) { newValue in
                        if newValue == nil {
                            selectedProfile = profiles.first
                        }
                    }
                    .onChange(of: profiles.count) { newValue in
                        if newValue > 0 && selectedProfile == nil {
                            selectedProfile = profiles.first
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                showingActionSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.circle")
                                        .font(.title2)
                                    Text("Select Profile")
                                        .font(.callout)
                                }
                                .foregroundColor(.secondary)
                            }
                            .actionSheet(isPresented: $showingActionSheet) {
                                ActionSheet(title: Text("Select Profile"), buttons: profiles.map { profile in
                                        .default(Text(profile.firstName ?? "")) {
                                            selectedProfile = profile
                                        }
                                } + [.cancel()])
                            }
                        }
                    }
                }
            }
        }
    }
}
