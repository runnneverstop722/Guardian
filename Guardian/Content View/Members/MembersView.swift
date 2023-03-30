//  Members.swift

import SwiftUI
import PhotosUI
import CloudKit

struct MembersView: View {
    @StateObject var profileModel: ProfileModel
    @State private var isMainUserSettingPresented = false
    @State private var showingRemoveDiagnosisAlert = false
    @State private var isUpdate = false
    @State private var editItem: MemberListModel?
    @Environment(\.presentationMode) var presentationMode
    
    let onUpdateProfile = NotificationCenter.default.publisher(for: Notification.Name("updateProfile"))
    init() {
        _profileModel = StateObject(wrappedValue: ProfileModel())
    }
    init(record: CKRecord) {
        _profileModel = StateObject(wrappedValue: ProfileModel(profile: record))
    }
    
    var body: some View {
        List {
            ForEach(profileModel.profileInfo, id: \.self) { item in
                NavigationLink(value: item) {
                    MembersListRow(headline: item.headline, caption: item.caption, image: item.image)
                        .onTapGesture {
                            profileModel.updateItem()
                        }
                }.swipeActions(edge: .leading) {
                    Button(role: .none) {
                        editItem = item
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    } .tint(.indigo)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        // Delete Item Action
                        profileModel.deleteItemsFromCloud(record: item.record) { isSuccess in
                            if isSuccess {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                        
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                    .alert(isPresented: $showingRemoveDiagnosisAlert) {
                        Alert(title: Text("Remove this diagnosis?"), message: Text("This action cannot be undone."), primaryButton: .destructive(Text("Remove")) {
                            // Handle removal of diagnosis
                            
                        }, secondaryButton: .cancel())
                    }
                }
            }
            .onMove(perform: move(fromOffsets:toOffset:))
        }
        .refreshable {
            profileModel.profileInfo = []
            profileModel.fetchItemsFromCloud()
        }
        .listStyle(.plain)
        .navigationTitle("管理メンバー")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("+新規") {
                    profileModel.isAddMemberPresented = true
                }
            }
        }
        .navigationDestination(for: MemberListModel.self) { item in
            YourRecordsView(profile: item.record)
        }
        .sheet(isPresented: $profileModel.isAddMemberPresented) {
            ProfileView()
        }
        .sheet(item: $editItem) { item in
            ProfileView(profile: item.record)
        }
        .onReceive(onUpdateProfile) { data in
            if let data = data.object as? CKRecord.ID {
                profileModel.profileInfo.removeAll { $0.record.recordID == data
                }
            } else if let data = data.object as? MemberListModel {
                profileModel.profileInfo.append(data)
            }
        }
    }
}

private extension MembersView {
    func editItems() {
        
    }
    
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        profileModel.profileInfo.move(fromOffsets: source, toOffset: destination)
    }
}

extension MembersView {
    struct MembersListRow: View {
        let headline: String
        let caption: String
        let image: Image?
        
        var body: some View {
            HStack(spacing: 16.0) {
                if let image = image {
                    image
                        .resizable()
                        .frame(width: 56.0, height: 56.0)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .scaledToFill()
                        .clipShape(Circle())
                        .font(.system(size: 30))
                        .frame(width: 56.0, height: 56.0)
                        .foregroundColor(.white)
                        .background {
                            Circle().fill(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                }
                VStack(alignment: .leading, spacing: 4.0) {
                    Text(headline)
                        .font(.headline)
                    Text(caption)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
//
//struct Members_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationStack {
//            MembersView()
//        }
//    }
//}
