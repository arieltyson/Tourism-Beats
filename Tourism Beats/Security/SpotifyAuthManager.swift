import AuthenticationServices
import CryptoKit
import Foundation
import UIKit

// MARK: - WebAuthPresenter

@MainActor
final class WebAuthPresenter: NSObject,
                              ASWebAuthenticationPresentationContextProviding
{
    static let shared = WebAuthPresenter()
    func presentationAnchor(for _: ASWebAuthenticationSession)
    -> ASPresentationAnchor
    {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow }) ?? UIWindow()
    }
}

// MARK: - SpotifyAuthManager

actor SpotifyAuthManager {
    static let shared = SpotifyAuthManager()

    private struct Token: Codable, Sendable {
        let accessToken: String
        let refreshToken: String?
        let expiresAt: Date
    }

    // Reuse encoders/decoders
    private static let jsonDecoder = JSONDecoder()
    private static let jsonEncoder = JSONEncoder()

    private var token: Token? = {
        guard let data = Keychain.get("spotify.token"),
              let t = try? SpotifyAuthManager.jsonDecoder.decode(
                Token.self,
                from: data
              )
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

    // MARK: - Token helpers

    private func isValid(_ t: Token?) -> Bool {
        guard let t else { return false }
        return t.expiresAt > Date().addingTimeInterval(30)
    }

    func hasUsableCachedToken() -> Bool { self.isValid(self.token) }

    func validAccessToken() async throws -> String {
        if self.isValid(self.token) { return self.token!.accessToken }
        if self.token?.refreshToken != nil { return try await self.refresh() }
        return try await self.authorize()
    }

    // MARK: - OAuth

    private func authorize() async throws -> String {
        let v = Self.randomURLSafeString(64)
        let s = Self.randomURLSafeString(24)
        self.verifier = v
        self.state = s

        let expectedVerifier = v
        let expectedState = s
        let challenge = Self.codeChallenge(for: v)

        var comps = URLComponents(
            url: authorizeURL,
            resolvingAgainstBaseURL: false
        )!
        comps.queryItems = [
            .init(name: "client_id", value: self.clientID),
            .init(name: "response_type", value: "code"),
            .init(name: "redirect_uri", value: self.redirectURI.absoluteString),
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
                    do {
                        let access = try await manager.exchange(
                            code: code,
                            verifier: expectedVerifier
                        )
                        cont.resume(returning: access)
                    } catch { cont.resume(throwing: error) }
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

        func enc(_ s: String) -> String {
            s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                ?? s
        }

        req.httpBody = [
            "client_id": self.clientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": self.redirectURI.absoluteString,
            "code_verifier": verifier
        ]
        .map { "\($0.key)=\(enc($0.value))" }
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
        let r = try Self.jsonDecoder.decode(Resp.self, from: data)

        let t = Token(
            accessToken: r.access_token,
            refreshToken: r.refresh_token,
            expiresAt: Date().addingTimeInterval(TimeInterval(r.expires_in))
        )
        self.token = t
        try? Keychain.set(Self.jsonEncoder.encode(t), for: "spotify.token")
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

        func enc(_ s: String) -> String {
            s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                ?? s
        }

        req.httpBody = [
            "client_id": self.clientID,
            "grant_type": "refresh_token",
            "refresh_token": refresh
        ]
        .map { "\($0.key)=\(enc($0.value))" }
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
        let r = try Self.jsonDecoder.decode(Resp.self, from: data)

        let new = Token(
            accessToken: r.access_token,
            refreshToken: r.refresh_token ?? self.token?.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(r.expires_in))
        )
        self.token = new
        try? Keychain.set(Self.jsonEncoder.encode(new), for: "spotify.token")
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
        return String((0 ..< length).compactMap { _ in chars.randomElement() })
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
