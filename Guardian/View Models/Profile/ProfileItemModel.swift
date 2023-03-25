//
//  ProfileItem.swift

import CloudKit

//MARK: - Gender
enum Gender: String, CaseIterable, Identifiable {
    case 男
    case 女
    case 選択なし
    var id: String { self.rawValue }
}

//MARK: - Properties
struct ProfileItemModel: Hashable {
    var id: String
    var firstName: String
    var lastName: String
    var gender: Gender
    var birthDate: Date
    var hospitalName: String = ""
    var allergist: String = ""
    var allergistContactInfo: String = ""
}
