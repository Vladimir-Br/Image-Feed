
import Foundation

enum ProfileServiceError: Error {
    case invalidRequest
    case notAuthorized
}

struct ProfileResult: Codable {
    let username: String
    let firstName: String?
    let lastName: String?
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case bio
    }
}

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
    
    init(from profileResult: ProfileResult) {
        self.username = profileResult.username
        let firstName = profileResult.firstName ?? ""
        let lastName = profileResult.lastName ?? ""
        self.name = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        self.loginName = "@\(profileResult.username)"
        self.bio = profileResult.bio
    }
}
