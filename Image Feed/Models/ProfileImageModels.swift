
import Foundation

enum ProfileImageServiceError: Error {
    case invalidRequest
    case notAuthorized
    case invalidData
}

struct UserResult: Codable {
    let profileImage: ProfileImageURL
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

struct ProfileImageURL: Codable {
    let small: String?
}
