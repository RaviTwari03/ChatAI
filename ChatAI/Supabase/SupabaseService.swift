//
//  SupabaseService.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 04/09/25.
//

import Foundation

enum SupabaseError: LocalizedError {
    case invalidURL
    case network(Error)
    case badStatus(Int, String?)
    case noData
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Supabase URL"
        case .network(let err): return err.localizedDescription
        case .badStatus(let code, let body):
            var base = "Unexpected status code: \(code)"
            if let body, !body.isEmpty { base += " — \(body)" }
            if code == 401 || code == 403 {
                if SupabaseAuth.shared.isLocalSession {
                    base += "\nHint: You're using local OTP auth (no real Supabase JWT). Either relax RLS for anon role on this table or sign in via a real provider (Google/Apple) to get a valid JWT."
                } else {
                    base += "\nHint: Ensure Authorization header contains a valid Supabase access token and the table RLS policies allow your role."
                }
            }
            return base
        case .noData: return "No data received"
        case .decoding(let err): return "Decoding error: \(err.localizedDescription)"
        }

    }
}

struct SupabaseService {
    let baseURL: URL
    let anonKey: String

    init(baseURL: URL = Secrets.supabaseUrl, anonKey: String = Secrets.supabaseAnonKey) {
        self.baseURL = baseURL
        self.anonKey = anonKey
    }

    // Simple connectivity check: GET /auth/v1/health should return 200
    func testConnection() async -> Result<Void, SupabaseError> {
        do {
            let healthURL = baseURL.appendingPathComponent("auth/v1/health")
            var req = URLRequest(url: healthURL)
            // Key header is optional for /health, but include to verify project binding
            req.addValue(anonKey, forHTTPHeaderField: "apikey")
            req.httpMethod = "GET"

            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { return .failure(.noData) }
            guard (200...299).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8)
                return .failure(.badStatus(http.statusCode, body))
            }
            _ = data // not used
            return .success(())
        } catch {
            return .failure(.network(error))
        }
    }

    // MARK: - Recent Chats REST helpers
    private var restBase: URL { baseURL.appendingPathComponent("/rest/v1") }

    private func authedRequest(url: URL, method: String, jsonBody: Data? = nil, prefer: String? = nil) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        req.addValue(anonKey, forHTTPHeaderField: "apikey")
        // Use user access token if it's a real Supabase token.
        // For local OTP sessions (pseudo token), fall back to anon key to avoid 401s from Supabase REST.
        if let token = SupabaseAuth.shared.accessToken, !token.isEmpty, !SupabaseAuth.shared.isLocalSession {
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            req.addValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        }
        // Pass verified email for local sessions so RLS can authorize on request.header('x-client-email')
        if SupabaseAuth.shared.isLocalSession, let email = SupabaseAuth.shared.lastEmail, !email.isEmpty {
            req.addValue(email, forHTTPHeaderField: "x-client-email")
        }
        if let prefer { req.addValue(prefer, forHTTPHeaderField: "Prefer") }
        req.httpBody = jsonBody
        return req
    }

    // DTOs to match Supabase columns
    private struct RecentChatRow: Codable {
        var id: UUID?
        var title: String
        var created_at: Date?
        var user_id: String?
        var user_email: String?
    }

    // Create/Upsert a recent chat
    func saveRecentChat(_ chat: RecentChat) async -> Result<RecentChat, SupabaseError> {
        do {
            let url = restBase.appendingPathComponent("recent_chats")
            let emailForLocal = SupabaseAuth.shared.isLocalSession ? SupabaseAuth.shared.lastEmail : nil
            let row = RecentChatRow(id: chat.id, title: chat.title, created_at: chat.createdAt, user_id: chat.userId, user_email: emailForLocal)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let body = try encoder.encode([row])
            let req = authedRequest(url: url, method: "POST", jsonBody: body, prefer: "return=representation")
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { return .failure(.noData) }
            guard (200...299).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8)
                return .failure(.badStatus(http.statusCode, bodyStr))
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let rows = try decoder.decode([RecentChatRow].self, from: data)
            guard let first = rows.first else { return .failure(.noData) }
            let saved = RecentChat(id: first.id ?? chat.id, title: first.title, createdAt: first.created_at ?? chat.createdAt, userId: first.user_id)
            return .success(saved)
        } catch let e as SupabaseError {
            return .failure(e)
        } catch let e as DecodingError {
            return .failure(.decoding(e))
        } catch {
            return .failure(.network(error))
        }
    }

    // Fetch recent chats (optionally scoped to a specific user)
    func fetchRecentChats(limit: Int = 20, userId: String? = nil) async -> Result<[RecentChat], SupabaseError> {
        do {
            var comps = URLComponents(url: restBase.appendingPathComponent("recent_chats"), resolvingAgainstBaseURL: false)!
            var items: [URLQueryItem] = [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "created_at.desc"),
                URLQueryItem(name: "limit", value: String(limit))
            ]
            if let userId, !userId.isEmpty {
                items.append(URLQueryItem(name: "user_id", value: "eq.\(userId)"))
            }
            comps.queryItems = items
            guard let url = comps.url else { return .failure(.invalidURL) }
            let req = authedRequest(url: url, method: "GET")
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { return .failure(.noData) }
            guard (200...299).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8)
                return .failure(.badStatus(http.statusCode, bodyStr))
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let rows = try decoder.decode([RecentChatRow].self, from: data)
            let mapped = rows.map { RecentChat(id: $0.id ?? UUID(), title: $0.title, createdAt: $0.created_at ?? Date(), userId: $0.user_id) }
            return .success(mapped)
        } catch let e as DecodingError {
            return .failure(.decoding(e))
        } catch {
            return .failure(.network(error))
        }
    }

    // Delete a recent chat by id (optionally assert user)
    func deleteRecentChat(id: UUID, userId: String? = nil) async -> Result<Void, SupabaseError> {
        do {
            var comps = URLComponents(url: restBase.appendingPathComponent("recent_chats"), resolvingAgainstBaseURL: false)!
            var items: [URLQueryItem] = [
                URLQueryItem(name: "id", value: "eq.\(id.uuidString)")
            ]
            if let userId, !userId.isEmpty {
                items.append(URLQueryItem(name: "user_id", value: "eq.\(userId)"))
            }
            comps.queryItems = items
            guard let url = comps.url else { return .failure(.invalidURL) }
            let req = authedRequest(url: url, method: "DELETE", prefer: "return=minimal")
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { return .failure(.noData) }
            guard (200...299).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8)
                return .failure(.badStatus(http.statusCode, bodyStr))
            }
            return .success(())
        } catch {
            return .failure(.network(error))
        }
    }

    // MARK: - RPC Helpers (Credits & Subscriptions)

    struct ConsumeResponse: Codable {
        let allowed: Bool
        let reason: String
        let tokens_left: Int
        let is_pro_active: Bool
        let provider: String
    }

    /// Checks if the current user has an active pro subscription
    func checkProStatus() async -> Bool {
        guard let userId = await SupabaseAuth.shared.userId else { return false }
        
        let result = await fetchMyCredits(userId: userId)
        switch result {
        case .success(let credits):
            // Check if user has active pro subscription
            if credits.is_pro {
                if let expiresAt = credits.pro_expires_at, let expiryDate = ISO8601DateFormatter().date(from: expiresAt) {
                    return expiryDate > Date()
                }
                return true // If no expiry date, assume it's a lifetime pro
            }
            return false
        case .failure(let error):
            print("Error checking pro status: \(error.localizedDescription)")
            return false
        }
    }

    /// Deducts one token for a search if user is not Pro; otherwise logs usage. Mirrors the consume_search_token RPC.
    func rpcConsumeSearchToken(provider: String) async -> Result<ConsumeResponse, SupabaseError> {
        do {
            let url = restBase.appendingPathComponent("rpc/consume_search_token")
            let payload = ["p_provider": provider]
            let body = try JSONSerialization.data(withJSONObject: payload, options: [])
            let req = authedRequest(url: url, method: "POST", jsonBody: body)
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { return .failure(.noData) }
            guard (200...299).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8)
                return .failure(.badStatus(http.statusCode, bodyStr))
            }
            let decoded = try JSONDecoder().decode(ConsumeResponse.self, from: data)
            return .success(decoded)
        } catch let e as SupabaseError {
            return .failure(e)
        } catch let e as DecodingError {
            return .failure(.decoding(e))
        } catch {
            return .failure(.network(error))
        }
    }

    struct ActivateProResponse: Codable {
        let ok: Bool
        let plan: String?
        let pro_expires_at: String?
    }

    /// Activates Pro for the current authenticated user. Mirrors the activate_pro_self RPC.
    func rpcActivateProSelf(plan: String, productId: String? = nil, transactionId: String? = nil, platform: String = "ios", environment: String? = nil) async -> Result<ActivateProResponse, SupabaseError> {
        do {
            let url = restBase.appendingPathComponent("rpc/activate_pro_self")
            let payload: [String: Any?] = [
                "p_plan": plan,
                "p_product_id": productId,
                "p_transaction_id": transactionId,
                "p_platform": platform,
                "p_environment": environment
            ]
            let body = try JSONSerialization.data(withJSONObject: payload.compactMapValues { $0 }, options: [])
            let req = authedRequest(url: url, method: "POST", jsonBody: body)
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { return .failure(.noData) }
            guard (200...299).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8)
                return .failure(.badStatus(http.statusCode, bodyStr))
            }
            let decoded = try JSONDecoder().decode(ActivateProResponse.self, from: data)
            return .success(decoded)
        } catch let e as SupabaseError {
            return .failure(e)
        } catch let e as DecodingError {
            return .failure(.decoding(e))
        } catch {
            return .failure(.network(error))
        }
    }

    /// Deactivates Pro for the current authenticated user. Mirrors the deactivate_pro_self RPC.
    func rpcDeactivateProSelf() async -> Result<Bool, SupabaseError> {
        do {
            let url = restBase.appendingPathComponent("rpc/deactivate_pro_self")
            let req = authedRequest(url: url, method: "POST", jsonBody: Data("{}".utf8))
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { return .failure(.noData) }
            guard (200...299).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8)
                return .failure(.badStatus(http.statusCode, bodyStr))
            }
            if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any], let ok = obj["ok"] as? Bool {
                return .success(ok)
            }
            return .failure(.noData)
        } catch let e as SupabaseError {
            return .failure(e)
        } catch {
            return .failure(.network(error))
        }
    }

    // MARK: - Credits Fetcher (for UI display)

    struct CreditsSnapshot: Codable {
        let tokens_balance: Int
        let is_pro: Bool
        let pro_expires_at: String?
    }

    /// Fetches the current user's credits and pro status via REST. Requires userId.
    func fetchMyCredits(userId: String) async -> Result<CreditsSnapshot, SupabaseError> {
        do {
            var comps = URLComponents(url: restBase.appendingPathComponent("app_user"), resolvingAgainstBaseURL: false)!
            comps.queryItems = [
                URLQueryItem(name: "select", value: "tokens_balance,is_pro,pro_expires_at"),
                URLQueryItem(name: "id", value: "eq.\(userId)"),
                URLQueryItem(name: "limit", value: "1")
            ]
            guard let url = comps.url else { return .failure(.invalidURL) }
            let req = authedRequest(url: url, method: "GET")
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { return .failure(.noData) }
            guard (200...299).contains(http.statusCode) else {
                let bodyStr = String(data: data, encoding: .utf8)
                return .failure(.badStatus(http.statusCode, bodyStr))
            }
            let rows = try JSONDecoder().decode([CreditsSnapshot].self, from: data)
            if let first = rows.first {
                return .success(first)
            }
            return .failure(.noData)
        } catch let e as SupabaseError {
            return .failure(e)
        } catch let e as DecodingError {
            return .failure(.decoding(e))
        } catch {
            return .failure(.network(error))
        }
    }

}
