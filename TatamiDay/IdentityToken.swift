import Foundation

enum IdentityToken {
    static func email(from token: Data?) -> String? {
        payload(from: token)?["email"] as? String
    }

    static func isPrivateRelay(_ token: Data?) -> Bool {
        let body = payload(from: token)
        if let value = body?["is_private_email"] as? String {
            return value.lowercased() == "true"
        }
        if let value = body?["is_private_email"] as? Bool {
            return value
        }
        return false
    }

    private static func payload(from token: Data?) -> [String: Any]? {
        guard let token, let string = String(data: token, encoding: .utf8) else { return nil }
        let parts = string.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var base = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base.count % 4
        if remainder > 0 {
            base += String(repeating: "=", count: 4 - remainder)
        }
        guard let data = Data(base64Encoded: base),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
}
