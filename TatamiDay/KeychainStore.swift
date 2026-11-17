import Foundation
import Security

enum KeychainAccount {
    static let userID = "userID"
    static let email = "email"
    static let givenName = "givenName"
    static let familyName = "familyName"
}

enum KeychainStore {
    private static let service = "com.idan.shoshany.tatamiday"

    static func set(_ value: String, account: String) {
        let query = baseQuery(account: account)
        SecItemDelete(query as CFDictionary)
        var insert = query
        insert[kSecValueData as String] = Data(value.utf8)
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(insert as CFDictionary, nil)
    }

    static func get(_ account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }

    static func deleteAll() {
        delete(KeychainAccount.userID)
        delete(KeychainAccount.email)
        delete(KeychainAccount.givenName)
        delete(KeychainAccount.familyName)
    }

    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
