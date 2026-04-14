//
//  GITGETApp.swift
//  GITGET
//
//  Created by Bo-Young PARK on 12/27/20.
//

import SwiftUI
import CryptoKit
import Security
import WebKit
#if canImport(UIKit)
import UIKit
#endif

@main
struct GITGETApp: App {
    @StateObject private var viewModel = ContributionWorkspaceViewModel()
    @StateObject private var gitLabAuth = GitLabAuthentication.shared

    var body: some Scene {
        WindowGroup {
            MainTabView(viewModel: viewModel, gitLabAuth: gitLabAuth)
        }
    }
}

@MainActor
final class GitLabAuthentication: NSObject, ObservableObject {
    static let shared = GitLabAuthentication()

    @Published private var clientIDsByOrigin: [String: String]
    @Published private var statusMessagesByOrigin: [String: String] = [:]
    @Published private var authenticatingOrigins: Set<String> = []
    @Published var activeWebLogin: GitLabWebLoginContext?

    private let userDefaults: UserDefaults
    private let tokenStore: GitLabTokenStore
    private let webSessionStore = GitLabWebSessionStore.shared
    private var signInContinuation: CheckedContinuation<Bool, Never>?
    private var pendingLogin: PendingGitLabLogin?

    private static let clientIDStoreKey = "gitlabOAuthClientIDs"
    private static let defaultBundleIdentifier = "kr.devfimuxd.gitget.0"

    private override init() {
        let defaults = UserDefaults.standard
        self.userDefaults = defaults
        self.tokenStore = GitLabTokenStore()
        self.clientIDsByOrigin = defaults.dictionary(forKey: Self.clientIDStoreKey) as? [String: String] ?? [:]
        super.init()
    }

    var redirectURIString: String {
        "\(callbackScheme)://oauth/callback"
    }

    private var callbackScheme: String {
        Bundle.main.bundleIdentifier ?? Self.defaultBundleIdentifier
    }

    func resolvedOrigin(serverOrigin: String?) -> String {
        ContributionProvider.gitlab.resolvedWebOriginString(serverOrigin: serverOrigin)
    }

    func clientID(forServerOrigin serverOrigin: String?) -> String {
        clientIDsByOrigin[resolvedOrigin(serverOrigin: serverOrigin)] ?? ""
    }

    func setClientID(_ clientID: String, forServerOrigin serverOrigin: String?) {
        let origin = resolvedOrigin(serverOrigin: serverOrigin)
        let trimmedClientID = clientID.trimmed

        if trimmedClientID.isEmpty {
            clientIDsByOrigin.removeValue(forKey: origin)
        } else {
            clientIDsByOrigin[origin] = trimmedClientID
        }

        userDefaults.set(clientIDsByOrigin, forKey: Self.clientIDStoreKey)
    }

    func statusMessage(forServerOrigin serverOrigin: String?) -> String? {
        statusMessagesByOrigin[resolvedOrigin(serverOrigin: serverOrigin)]
    }

    func isAuthenticating(serverOrigin: String?) -> Bool {
        authenticatingOrigins.contains(resolvedOrigin(serverOrigin: serverOrigin))
    }

    func isAuthenticated(serverOrigin: String?) -> Bool {
        (try? tokenStore.read(forOrigin: resolvedOrigin(serverOrigin: serverOrigin))) != nil
    }

    func signOut(serverOrigin: String?) {
        let origin = resolvedOrigin(serverOrigin: serverOrigin)
        try? tokenStore.delete(forOrigin: origin)
        Task { await webSessionStore.clearCookies(forOrigin: origin) }
        statusMessagesByOrigin[origin] = "Signed out from \(origin)."
    }

    @discardableResult
    func signIn(serverOrigin: String?) async -> Bool {
        let origin = resolvedOrigin(serverOrigin: serverOrigin)
        let clientID = clientIDsByOrigin[origin]?.trimmed ?? ""

        guard !clientID.isEmpty else {
            statusMessagesByOrigin[origin] = "Enter the GitLab OAuth Client ID first."
            return false
        }

        if clientID.lowercased().hasPrefix("glpat-") {
            statusMessagesByOrigin[origin] = "The value you entered starts with 'glpat-', which is a GitLab Personal Access Token. Enter the OAuth application's Client ID instead."
            return false
        }

        let pkce = GitLabPKCE.generate()
        let state = GitLabPKCE.randomURLSafeString(length: 32)
        let nonce = GitLabPKCE.randomURLSafeString(length: 32)

        guard let authorizationURL = makeAuthorizationURL(origin: origin, clientID: clientID, pkce: pkce, state: state, nonce: nonce) else {
            statusMessagesByOrigin[origin] = "Could not build the GitLab authorization URL."
            return false
        }

        authenticatingOrigins.insert(origin)
        statusMessagesByOrigin[origin] = "Opening GitLab sign-in for \(origin)..."
        let loginContext = GitLabWebLoginContext(origin: origin, authorizationURL: authorizationURL, callbackScheme: callbackScheme)
        pendingLogin = PendingGitLabLogin(origin: origin, clientID: clientID, pkce: pkce, state: state)
        activeWebLogin = loginContext

        defer {
            authenticatingOrigins.remove(origin)
        }

        return await withCheckedContinuation { continuation in
            signInContinuation = continuation
        }
    }

    func cancelPresentedLoginIfNeeded() {
        guard let pendingLogin else {
            activeWebLogin = nil
            return
        }

        statusMessagesByOrigin[pendingLogin.origin] = "GitLab sign-in was cancelled."
        completePendingLogin(success: false)
    }

    func handleWebLoginCallback(_ callbackURL: URL) async {
        guard let pendingLogin else {
            return
        }

        do {
            let authorizationCode = try parseAuthorizationCode(from: callbackURL, expectedState: pendingLogin.state)
            let tokens = try await exchangeCodeForTokens(origin: pendingLogin.origin, clientID: pendingLogin.clientID, code: authorizationCode, pkce: pendingLogin.pkce)
            try tokenStore.write(tokens, forOrigin: pendingLogin.origin)
            await webSessionStore.syncCookiesIntoSharedStorage()
            statusMessagesByOrigin[pendingLogin.origin] = "Signed in to \(pendingLogin.origin)."
            completePendingLogin(success: true)
        } catch {
            statusMessagesByOrigin[pendingLogin.origin] = error.localizedDescription
            completePendingLogin(success: false)
        }
    }

    var isShowingWebLogin: Bool {
        activeWebLogin != nil
    }

    var sharedWebsiteDataStore: WKWebsiteDataStore {
        webSessionStore.websiteDataStore
    }

    func authorizedRequest(_ request: URLRequest, for account: ContributionAccount) async -> URLRequest {
        guard account.provider == .gitlab else {
            return request
        }

        guard let token = try? await validAccessToken(forOrigin: resolvedOrigin(serverOrigin: account.serverOrigin)) else {
            return request
        }

        var authorizedRequest = request
        authorizedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return authorizedRequest
    }

    private func validAccessToken(forOrigin origin: String) async throws -> String? {
        guard var tokens = try tokenStore.read(forOrigin: origin) else {
            return nil
        }

        if !tokens.isExpired {
            return tokens.accessToken
        }

        guard let refreshToken = tokens.refreshToken,
              let clientID = clientIDsByOrigin[origin],
              !clientID.trimmed.isEmpty else {
            return nil
        }

        let refreshedTokens = try await refreshTokens(origin: origin, clientID: clientID, refreshToken: refreshToken)
        try tokenStore.write(refreshedTokens, forOrigin: origin)
        tokens = refreshedTokens
        statusMessagesByOrigin[origin] = "Refreshed GitLab session for \(origin)."
        return tokens.accessToken
    }

    private func makeAuthorizationURL(origin: String, clientID: String, pkce: GitLabPKCE, state: String, nonce: String) -> URL? {
        guard var components = URLComponents(string: origin + "/oauth/authorize") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURIString),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "read_api read_user"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: pkce.codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "nonce", value: nonce)
        ]
        return components.url
    }

    private func parseAuthorizationCode(from callbackURL: URL, expectedState: String) throws -> String {
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            throw GitLabAuthenticationError.invalidCallback
        }

        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        if let errorDescription = items["error_description"], !errorDescription.isEmpty {
            throw GitLabAuthenticationError.providerError(errorDescription)
        }

        if let errorValue = items["error"], !errorValue.isEmpty {
            throw GitLabAuthenticationError.providerError(errorValue)
        }

        guard items["state"] == expectedState else {
            throw GitLabAuthenticationError.invalidState
        }

        guard let code = items["code"], !code.isEmpty else {
            throw GitLabAuthenticationError.missingAuthorizationCode
        }

        return code
    }

    private func exchangeCodeForTokens(origin: String, clientID: String, code: String, pkce: GitLabPKCE) async throws -> GitLabOAuthTokens {
        try await performTokenRequest(
            origin: origin,
            parameters: [
                "grant_type": "authorization_code",
                "code": code,
                "client_id": clientID,
                "redirect_uri": redirectURIString,
                "code_verifier": pkce.codeVerifier
            ]
        )
    }

    private func refreshTokens(origin: String, clientID: String, refreshToken: String) async throws -> GitLabOAuthTokens {
        try await performTokenRequest(
            origin: origin,
            parameters: [
                "grant_type": "refresh_token",
                "refresh_token": refreshToken,
                "client_id": clientID
            ]
        )
    }

    private func performTokenRequest(origin: String, parameters: [String: String]) async throws -> GitLabOAuthTokens {
        guard let tokenURL = URL(string: origin + "/oauth/token") else {
            throw GitLabAuthenticationError.invalidTokenEndpoint
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameters
            .sorted { $0.key < $1.key }
            .map { key, value in
                let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(escapedKey)=\(escapedValue)"
            }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitLabAuthenticationError.invalidTokenResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let serverMessage = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw GitLabAuthenticationError.tokenExchangeFailed(statusCode: httpResponse.statusCode, message: serverMessage)
        }

        let decodedResponse = try JSONDecoder().decode(GitLabOAuthTokenResponse.self, from: data)
        return decodedResponse.tokens
    }

    private func completePendingLogin(success: Bool) {
        activeWebLogin = nil
        pendingLogin = nil
        signInContinuation?.resume(returning: success)
        signInContinuation = nil
    }
}

struct GitLabWebLoginContext: Identifiable, Equatable {
    let id = UUID()
    let origin: String
    let authorizationURL: URL
    let callbackScheme: String
}

private struct PendingGitLabLogin {
    let origin: String
    let clientID: String
    let pkce: GitLabPKCE
    let state: String
}

@MainActor
private final class GitLabWebSessionStore {
    static let shared = GitLabWebSessionStore()

    let websiteDataStore = WKWebsiteDataStore.default()

    func syncCookiesIntoSharedStorage() async {
        let cookies = await allCookies()
        for cookie in cookies {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }

    func clearCookies(forOrigin origin: String) async {
        guard let host = URL(string: origin)?.host else {
            return
        }

        let cookies = await allCookies()
        for cookie in cookies where cookie.domain.contains(host) {
            websiteDataStore.httpCookieStore.delete(cookie)
        }

        HTTPCookieStorage.shared.cookies?
            .filter { $0.domain.contains(host) }
            .forEach { HTTPCookieStorage.shared.deleteCookie($0) }
    }

    private func allCookies() async -> [HTTPCookie] {
        await withCheckedContinuation { continuation in
            websiteDataStore.httpCookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }
    }
}

struct GitLabWebAuthenticationSheet: View {
    let context: GitLabWebLoginContext
    @ObservedObject var auth: GitLabAuthentication
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            GitLabWebAuthenticationView(context: context, websiteDataStore: auth.sharedWebsiteDataStore) { callbackURL in
                Task {
                    await auth.handleWebLoginCallback(callbackURL)
                    dismiss()
                }
            }
            .navigationTitle("GitLab Sign-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        auth.cancelPresentedLoginIfNeeded()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GitLabWebAuthenticationView: UIViewRepresentable {
    let context: GitLabWebLoginContext
    let websiteDataStore: WKWebsiteDataStore
    let onCallback: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(context: context, onCallback: onCallback)
    }

    func makeUIView(context uiContext: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = websiteDataStore
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = uiContext.coordinator
        webView.load(URLRequest(url: context.authorizationURL))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let context: GitLabWebLoginContext
        private let onCallback: (URL) -> Void

        init(context: GitLabWebLoginContext, onCallback: @escaping (URL) -> Void) {
            self.context = context
            self.onCallback = onCallback
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url,
               url.scheme == context.callbackScheme {
                decisionHandler(.cancel)
                onCallback(url)
                return
            }

            decisionHandler(.allow)
        }
    }
}

private struct GitLabPKCE {
    let codeVerifier: String
    let codeChallenge: String

    static func generate() -> GitLabPKCE {
        let verifier = randomURLSafeString(length: 64)
        let digest = SHA256.hash(data: Data(verifier.utf8))
        let challenge = Data(digest).base64URLEncodedString()
        return GitLabPKCE(codeVerifier: verifier, codeChallenge: challenge)
    }

    static func randomURLSafeString(length: Int) -> String {
        let characters = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
        return String((0..<length).map { _ in characters.randomElement() ?? "a" })
    }
}

private struct GitLabOAuthTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }

    var tokens: GitLabOAuthTokens {
        GitLabOAuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: expiresIn.map { Date().addingTimeInterval(TimeInterval($0)) }
        )
    }
}

private struct GitLabOAuthTokens: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date?

    var isExpired: Bool {
        guard let expiresAt else {
            return false
        }

        return expiresAt <= Date().addingTimeInterval(30)
    }
}

private enum GitLabAuthenticationError: LocalizedError {
    case invalidCallback
    case invalidState
    case missingAuthorizationCode
    case invalidTokenEndpoint
    case invalidTokenResponse
    case providerError(String)
    case tokenExchangeFailed(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidCallback:
            return "GitLab sign-in returned an invalid callback."
        case .invalidState:
            return "GitLab sign-in state did not match the request."
        case .missingAuthorizationCode:
            return "GitLab sign-in did not return an authorization code."
        case .invalidTokenEndpoint:
            return "Could not build the GitLab token endpoint."
        case .invalidTokenResponse:
            return "GitLab token exchange returned an invalid response."
        case .providerError(let message):
            return "GitLab sign-in failed: \(message)"
        case .tokenExchangeFailed(let statusCode, let message):
            if let message, !message.isEmpty {
                return "GitLab token exchange failed (HTTP \(statusCode)): \(message)"
            }

            return "GitLab token exchange failed with HTTP \(statusCode)."
        }
    }
}

private final class GitLabTokenStore {
    private let service = "kr.devfimuxd.gitget.0.gitlab.tokens"
    private let fallbackKeyPrefix = "gitlabOAuthFallbackTokens."
    private let userDefaults = UserDefaults.standard

    func read(forOrigin origin: String) throws -> GitLabOAuthTokens? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: origin,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { return nil }
            return try JSONDecoder().decode(GitLabOAuthTokens.self, from: data)
        case errSecItemNotFound:
            return fallbackTokens(forOrigin: origin)
        case errSecMissingEntitlement, errSecNotAvailable:
            return fallbackTokens(forOrigin: origin)
        default:
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    func write(_ tokens: GitLabOAuthTokens, forOrigin origin: String) throws {
        let data = try JSONEncoder().encode(tokens)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: origin
        ]
        let attributes: [CFString: Any] = [
            kSecValueData: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var insertQuery = query
            insertQuery[kSecValueData] = data
            let insertStatus = SecItemAdd(insertQuery as CFDictionary, nil)
            if insertStatus == errSecMissingEntitlement || insertStatus == errSecNotAvailable {
                storeFallbackTokens(data, forOrigin: origin)
                return
            }
            guard insertStatus == errSecSuccess else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(insertStatus))
            }
            return
        }

        if updateStatus == errSecMissingEntitlement || updateStatus == errSecNotAvailable {
            storeFallbackTokens(data, forOrigin: origin)
            return
        }

        guard updateStatus == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(updateStatus))
        }
    }

    func delete(forOrigin origin: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: origin
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecMissingEntitlement || status == errSecNotAvailable {
            userDefaults.removeObject(forKey: fallbackKey(forOrigin: origin))
            return
        }
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }

        userDefaults.removeObject(forKey: fallbackKey(forOrigin: origin))
    }

    private func fallbackTokens(forOrigin origin: String) -> GitLabOAuthTokens? {
        guard let data = userDefaults.data(forKey: fallbackKey(forOrigin: origin)) else {
            return nil
        }

        return try? JSONDecoder().decode(GitLabOAuthTokens.self, from: data)
    }

    private func storeFallbackTokens(_ data: Data, forOrigin origin: String) {
        userDefaults.set(data, forKey: fallbackKey(forOrigin: origin))
    }

    private func fallbackKey(forOrigin origin: String) -> String {
        fallbackKeyPrefix + origin
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
