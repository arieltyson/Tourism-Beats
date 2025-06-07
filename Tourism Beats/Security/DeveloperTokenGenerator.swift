import CryptoKit
import Foundation

struct DeveloperTokenGenerator {
    private static var cachedToken: String?
    private static var tokenExpiresAt: Date?

    static func generateDeveloperToken() throws -> String {
        if let token = cachedToken,
            let expires = tokenExpiresAt,
            expires > Date()
        {
            return token
        }

        // Build a fresh JWT…
        let header = JWTHeader(kid: Secrets.musicKitKeyID)
        let payload = JWTPayload(
            iss: Secrets.teamID,
            iat: Date(),
            exp: Date().addingTimeInterval(3600)  // valid 1h
        )

        let headerString = try encode(header).toBase64URL()
        let payloadString = try encode(payload).toBase64URL()
        let signature = try sign(header: headerString, payload: payloadString)

        let token = "\(headerString).\(payloadString).\(signature)"
        cachedToken = token
        tokenExpiresAt = payload.exp
        return token
    }

    private static func sign(header: String, payload: String) throws -> String {
        let privateKey = try P256.Signing.PrivateKey(
            pemRepresentation: Secrets.musicKitPrivateKey
        )
        let dataToSign = Data("\(header).\(payload)".utf8)
        let sig = try privateKey.signature(for: dataToSign)
        return sig.rawRepresentation.toBase64URL()
    }

    private struct JWTHeader: Encodable {
        let alg = "ES256"
        let kid: String
    }
    private struct JWTPayload: Encodable {
        let iss: String
        let iat: Date
        let exp: Date
    }
}

private func encode<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970
    return try encoder.encode(value)
}
extension Data {
    fileprivate func toBase64URL() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
