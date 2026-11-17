import Foundation

/// This copy of Tatami Day opens for one Apple ID only.
enum AccessPolicy {
    static let allowedEmail = "idan.shoshany.2011@gmail.com"

    static func allows(email: String?) -> Bool {
        guard let email else { return false }
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == allowedEmail
    }
}
