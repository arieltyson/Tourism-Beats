import CryptoKit
import Foundation

struct DeveloperTokenGenerator {

    /// Generates a developer token valid for a short period.
    static func generateDeveloperToken() throws -> String {
        let header = JWTHeader(kid: Secrets.musicKitKeyID)

        let payload = JWTPayload(
            iss: Secrets.teamID,
            iat: Date(),
            exp: Date().addingTimeInterval(3600)  // Token valid for 1 hour
        )

        let headerString = try encode(header).toBase64URL()
        let payloadString = try encode(payload).toBase64URL()

        let signatureString = try sign(
            header: headerString,
            payload: payloadString
        )

        return "\(headerString).\(payloadString).\(signatureString)"
    }

    /// Signs the header and payload to create the final token component.
    private static func sign(header: String, payload: String) throws -> String {
        let privateKey = try P256.Signing.PrivateKey(
            pemRepresentation: Secrets.musicKitPrivateKey
        )

        let dataToSign = Data("\(header).\(payload)".utf8)
        let signature = try privateKey.signature(for: dataToSign)

        return signature.rawRepresentation.toBase64URL()
    }

    // MARK: - JWT Helper Structs

    private struct JWTHeader: Encodable {
        let alg = "ES256"
        let kid: String
    }

    private struct JWTPayload: Encodable {
        let iss: String  // Issuer (Team ID)
        let iat: Date  // Issued At
        let exp: Date  // Expiration
    }
}

// MARK: - Helper Extensions

extension Data {
    fileprivate func toBase64URL() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private func encode<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970  // Standard for JWT
    return try encoder.encode(value)
}
