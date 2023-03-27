//  Members.swift

import SwiftUI
import PhotosUI
import CloudKit

struct MembersView: View {
    @State private var isMainUserSettingPresented = false
    @StateObject var profileModel: ProfileModel 
    @State private var isUpdate = false
    @State private var editItem: MemberListModel?
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
                    Row(headline: item.headline, caption: item.caption, image: item.image)
                        .onTapGesture {
                            profileModel.updateItem(model: item)
                        }
                }.swipeActions(allowsFullSwipe: false) {
                    Button("Edit") {
                        editItem = item
                    }

                    Button(role: .destructive) {
//                        profileModel.profileInfo.removeAll(where: { $0.id == item.id })
//                        if let record = item.record {
//                            profileModel.deleteItemsFromCloud() { success in
//                                if success {
//                                    NotificationCenter.default.post(name: NSNotification.Name("ItemDeleted"), object: nil)
//                                } else {
//                                    // Handle deletion failure
//                                }
//                            }
//                        }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
            }
            .onDelete(perform: deleteItems(atOffsets:))
            .onMove(perform: move(fromOffsets:toOffset:))
        }
        .refreshable {
            profileModel.profileInfo = []
            profileModel.fetchItemsFromCloud()
        }
        .listStyle(.plain)
        .navigationTitle("Member List")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("+Add") {
                    profileModel.isAddMemberPresented = true
                }
            }
        }
        .navigationDestination(for: MemberListModel.self) { item in
            MemberDetailView(profile: item.record)
        }
        .sheet(isPresented: $profileModel.isAddMemberPresented) {
            ProfileView()
        }
        .sheet(item: $editItem) { item in
            ProfileView(profile: item.record)
        }
    }
}

private extension MembersView {
    
    func deleteItems(atOffsets offsets: IndexSet) {
        profileModel.profileInfo.remove(atOffsets: offsets)
    }
    
    func editItems() {
        
    }
    
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        profileModel.profileInfo.move(fromOffsets: source, toOffset: destination)
    }
}

extension MembersView {
    struct Row: View {
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
