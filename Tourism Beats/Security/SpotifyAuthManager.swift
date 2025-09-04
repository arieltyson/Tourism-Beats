import Foundation
import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - Main-actor presenter for ASWebAuthenticationSession
@MainActor
final class WebAuthPresenter: NSObject,
    ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthPresenter()

    func presentationAnchor(for session: ASWebAuthenticationSession)
        -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow }) ?? UIWindow()
    }
}

// MARK: - Auth manager (actor)
actor SpotifyAuthManager {
    static let shared = SpotifyAuthManager()

    private struct Token: Codable, Sendable {
        let accessToken: String
        let refreshToken: String?
        let expiresAt: Date
    }

    private var token: Token? = {
        guard let data = Keychain.get("spotify.token"),
            let t = try? JSONDecoder().decode(Token.self, from: data)
        else { return nil }
        return t
    }()

    private let clientID = Secrets.spotifyClientID
    private let redirectURI = Secrets.spotifyRedirectURI
    private let authorizeURL = URL(
        string: "https://accounts.spotify.com/authorize"
    )!
    private let tokenURL = URL(
        string: "https://accounts.spotify.com/api/token"
    )!

    private var verifier: String?
    private var state: String?

    // Exposed so UI can grey/enable Spotify pill without prompting
    func hasUsableCachedToken() -> Bool {
        if let t = token, t.expiresAt > Date().addingTimeInterval(30) {
            return true
        }
        return false
    }

    func validAccessToken() async throws -> String {
        if let t = token, t.expiresAt > Date().addingTimeInterval(30) {
            return t.accessToken
        }
        if token?.refreshToken != nil { return try await refresh() }
        return try await authorize()
    }

    private func authorize() async throws -> String {
        let v = Self.randomURLSafeString(64)
        let s = Self.randomURLSafeString(24)
        verifier = v
        state = s

        let expectedVerifier = v
        let expectedState = s
        let challenge = Self.codeChallenge(for: v)

        var comps = URLComponents(
            url: authorizeURL,
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [
            .init(name: "client_id", value: clientID),
            .init(name: "response_type", value: "code"),
            .init(name: "redirect_uri", value: redirectURI.absoluteString),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "code_challenge", value: challenge),
            .init(name: "state", value: s),
            .init(name: "show_dialog", value: "false")
        ]
        let authURL = comps.url!

        return try await withCheckedThrowingContinuation { cont in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: redirectURI.scheme
            ) {
                [manager = self, expectedVerifier, expectedState] callback, err
                in
                guard err == nil,
                    let url = callback,
                    let items = URLComponents(
                        url: url,
                        resolvingAgainstBaseURL: false
                    )?.queryItems,
                    let code = items.first(where: { $0.name == "code" })?.value,
                    let back = items.first(where: { $0.name == "state" })?
                        .value,
                    back == expectedState
                else {
                    cont.resume(throwing: AuthError.authorizationFailed)
                    return
                }

                Task.detached(priority: .userInitiated) {
                    [manager, continuation = cont, expectedVerifier, code] in
                    do {
                        let access = try await manager.exchange(
                            code: code,
                            verifier: expectedVerifier
                        )
                        continuation.resume(returning: access)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            session.prefersEphemeralWebBrowserSession = true
            Task { @MainActor in
                session.presentationContextProvider = WebAuthPresenter.shared
                _ = session.start()
            }
        }
    }

    private func exchange(code: String, verifier: String) async throws -> String {
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )
        req.httpBody = [
            "client_id": clientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI.absoluteString,
            "code_verifier": verifier
        ].map {
            "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
        }
        .joined(separator: "&")
        .data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw AuthError.tokenExchangeFailed
        }

        struct Resp: Decodable {
            let access_token: String
            let refresh_token: String?
            let expires_in: Int
        }
        let r = try JSONDecoder().decode(Resp.self, from: data)

        let t = Token(
            accessToken: r.access_token,
            refreshToken: r.refresh_token,
            expiresAt: Date().addingTimeInterval(TimeInterval(r.expires_in))
        )
        token = t
        try? Keychain.set(JSONEncoder().encode(t), for: "spotify.token")
        return t.accessToken
    }

    private func refresh() async throws -> String {
        guard let refresh = token?.refreshToken else {
            throw AuthError.noRefreshToken
        }

        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )
        req.httpBody = [
            "client_id": clientID,
            "grant_type": "refresh_token",
            "refresh_token": refresh
        ].map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw AuthError.refreshFailed
        }

        struct Resp: Decodable {
            let access_token: String
            let expires_in: Int
            let refresh_token: String?
        }
        let r = try JSONDecoder().decode(Resp.self, from: data)

        let new = Token(
            accessToken: r.access_token,
            refreshToken: r.refresh_token ?? token?.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(r.expires_in))
        )
        token = new
        try? Keychain.set(JSONEncoder().encode(new), for: "spotify.token")
        return new.accessToken
    }

    enum AuthError: Error {
        case authorizationFailed, tokenExchangeFailed, refreshFailed,
            noRefreshToken
    }

    static func randomURLSafeString(_ length: Int) -> String {
        let chars = Array(
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        )
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }

    static func codeChallenge(for verifier: String) -> String {
        let data = Data(verifier.utf8)
        let digest = Data(SHA256.hash(data: data))
        return digest.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
