import CryptoKit
import Foundation

enum AccountAccess {
    static let reviewerEmail = "reviewer@tatamiday.app"
    static let reviewerPassword = "TatamiReview2026"

    struct Record: Codable, Equatable {
        var email: String
        var salt: String
        var passwordHash: String
    }

    static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func emailKey(_ email: String) -> String {
        "email:\(normalizedEmail(email))"
    }

    static func appleKey(_ userID: String) -> String {
        "apple:\(userID)"
    }

    static func ensureReviewer() {
        let email = reviewerEmail
        var records = load()
        guard !records.contains(where: { $0.email == email }) else { return }
        let salt = UUID().uuidString
        records.append(Record(email: email, salt: salt, passwordHash: hash(reviewerPassword, salt: salt)))
        save(records)
    }

    static func authenticate(email: String, password: String) -> String? {
        ensureReviewer()
        let normalized = normalizedEmail(email)
        guard let record = load().first(where: { $0.email == normalized }),
              hash(password, salt: record.salt) == record.passwordHash else {
            return nil
        }
        return emailKey(normalized)
    }

    enum SignupFailure: Error {
        case invalidEmail
        case shortPassword
        case passwordMismatch
        case alreadyExists

        var message: String {
            switch self {
            case .invalidEmail:
                "Enter a valid email address."
            case .shortPassword:
                "Use at least 8 characters for the password."
            case .passwordMismatch:
                "The passwords do not match."
            case .alreadyExists:
                "An account with that email already exists. Sign in instead."
            }
        }
    }

    static func register(email: String, password: String, confirm: String) -> Result<String, SignupFailure> {
        ensureReviewer()
        let normalized = normalizedEmail(email)
        guard normalized.contains("@"), normalized.contains(".") else {
            return .failure(.invalidEmail)
        }
        guard password.count >= 8 else {
            return .failure(.shortPassword)
        }
        guard password == confirm else {
            return .failure(.passwordMismatch)
        }
        var records = load()
        guard !records.contains(where: { $0.email == normalized }) else {
            return .failure(.alreadyExists)
        }
        let salt = UUID().uuidString
        records.append(Record(email: normalized, salt: salt, passwordHash: hash(password, salt: salt)))
        save(records)
        return .success(emailKey(normalized))
    }

    static func hasEmail(_ email: String) -> Bool {
        let normalized = normalizedEmail(email)
        return load().contains { $0.email == normalized }
    }

    static func remove(email: String) {
        let normalized = normalizedEmail(email)
        guard normalized != reviewerEmail else { return }
        save(load().filter { $0.email != normalized })
    }

    private static func hash(_ password: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((salt + password).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func load() -> [Record] {
        guard let url = try? directoryURL().appendingPathComponent("passwords.json"),
              let data = try? Data(contentsOf: url),
              let records = try? JSONDecoder().decode([Record].self, from: data) else {
            return []
        }
        return records
    }

    private static func save(_ records: [Record]) {
        guard let url = try? directoryURL().appendingPathComponent("passwords.json"),
              let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private static func directoryURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = base.appendingPathComponent("TatamiDay", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}
