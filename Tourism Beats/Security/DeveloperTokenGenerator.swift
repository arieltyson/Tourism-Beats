import CryptoKit
import Foundation

// MARK: - Developer Token Generator Actor

actor DeveloperTokenGenerator {

    static let shared = DeveloperTokenGenerator()

    private var cachedToken: String?
    private var tokenExpiresAt: Date?

    private init() {}

    /// Generates a developer token for MusicKit, using a cached token if available and valid.
    func generateDeveloperToken() async throws -> String {
        if let token = cachedToken,
            let expires = tokenExpiresAt,
            expires > Date()
        {
            return token
        }

        // --- Build a fresh JWT ---
        let header = JWTHeader(kid: Secrets.musicKitKeyID)
        let expirationDate = Date().addingTimeInterval(3600)  // Stays valid for 1 hour
        let payload = JWTPayload(
            iss: Secrets.teamID,
            iat: Date(),
            exp: expirationDate
        )

        let headerString = try encode(header).toBase64URL()
        let payloadString = try encode(payload).toBase64URL()
        let signature = try sign(header: headerString, payload: payloadString)

        let token = "\(headerString).\(payloadString).\(signature)"

        cachedToken = token
        tokenExpiresAt = expirationDate

        return token
    }

    /// Signs the JWT header and payload to create a signature.
    private func sign(header: String, payload: String) throws -> String {
        let privateKey = try P256.Signing.PrivateKey(
            pemRepresentation: Secrets.musicKitPrivateKey
        )
        let dataToSign = Data("\(header).\(payload)".utf8)
        let signature = try privateKey.signature(for: dataToSign)

        return signature.rawRepresentation.toBase64URL()
    }

    // MARK: - Private JWT Structures

    private struct JWTHeader: Encodable {
        let alg = "ES256"
        let kid: String
    }

    private struct JWTPayload: Encodable {
        let iss: String  // Issuer (Your Team ID)
        let iat: Date  // Issued At
        let exp: Date  // Expiration Time
    }
}

// MARK: - Helper Functions (File Private)

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
