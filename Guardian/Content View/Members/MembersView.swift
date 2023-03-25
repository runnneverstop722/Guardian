//  Members.swift

import SwiftUI
import PhotosUI
import CloudKit

struct MembersView: View {
    @StateObject var vm = ProfileModel()
    @State private var isMainUserSettingPresented = false
    
    
    var body: some View {
        List {
            ForEach(vm.profileInfo, id: \.self) { item in
                NavigationLink(value: item) {
                    Row(headline: item.headline, caption: item.caption, image: item.image)
                        .onTapGesture {
                            vm.updateItem(model: item)
                        }
                }
            }
            .onDelete(perform: deleteItems(atOffsets:))
            .onMove(perform: move(fromOffsets:toOffset:))
        }
        .refreshable {
            vm.profileInfo = []
            vm.fetchItemsFromCloud()
        }
        .listStyle(.plain)
        .navigationTitle("Member List")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("+Add Member") {
                    vm.isAddMemberPresented = true
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Edit Member") {
                    vm.isEditMemberPresented = true
                }
            }
        }
        .navigationDestination(for: MemberList.self) { item in
            MemberDetailView(profile: item.record)
        }
        .sheet(isPresented: $vm.isAddMemberPresented) {
            NewProfileView()
        }
    }
}

private extension MembersView {
    
    func deleteItems(atOffsets offsets: IndexSet) {
        vm.profileInfo.remove(atOffsets: offsets)
    }
    
    func editItems() {
        
    }
    
    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        vm.profileInfo.move(fromOffsets: source, toOffset: destination)
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

struct Members_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MembersView()
        }
    }
}
