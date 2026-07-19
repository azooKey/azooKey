import Foundation

struct HotfixDictionaryV1: Codable {
    /// Metadata about the file itself (status, version, etc.)
    let metadata: Metadata
    /// Array of dictionary entries.
    let data: [Entry]

    // MARK: - Nested Types

    /// Corresponds to the `"metadata"` object.
    struct Metadata: Codable {
        let status: Status
        let name: String
        let description: String
        let version: String
        let lastUpdate: String  // ISO‑8601 文字列 (例: "2025-05-04T12:00:00.00")

        enum Status: String, Codable {
            case active
            case disabled
        }

        enum CodingKeys: String, CodingKey {
            case status, name, description, version
            case lastUpdate = "last_update"
        }

        var lastUpdateDate: Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SS"
            return formatter.date(from: self.lastUpdate)
        }
    }

    /// One element of the `"data"` array (a single vocabulary entry).
    struct Entry: Codable {
        let word: String
        let ruby: String
        let wordWeight: Double     // 負の値ほど優先度が高い
        let lcid: Int
        let rcid: Int
        let mid: Int
        let date: String        // "YYYY-MM-DD"
        let author: String

        enum CodingKeys: String, CodingKey {
            case word, ruby
            case wordWeight = "word_weight"
            case lcid, rcid, mid, date, author
        }
    }
}

// MARK: - Convenience Loading Helpers
extension HotfixDictionaryV1 {
    /// Decode `HotfixDictionaryV1` from raw JSON `Data`.
    static func load(from jsonData: Data) throws -> HotfixDictionaryV1 {
        let decoder = JSONDecoder()
        // `.convertFromSnakeCase` would work, but CodingKeys give us explicit control
        return try decoder.decode(HotfixDictionaryV1.self, from: jsonData)
    }

    /// Decode from a file `URL` or remote `URL` asynchronously (throws on failure).
    static func load(from url: URL, using encoding: String.Encoding = .utf8) async throws -> HotfixDictionaryV1 {
        if url.isFileURL {
            // Local file URLs can still be read synchronously without affecting the main thread.
            let data = try Data(contentsOf: url)
            return try load(from: data)
        } else {
            // Remote URLs are fetched asynchronously to avoid blocking the main thread.
            let (data, _) = try await URLSession.shared.data(from: url)
            return try load(from: data)
        }
    }

    /// Fetch the latest release tag from GitHub and cache it in `UserDefaults`.
    /// - Returns: The latest tag string (e.g., "v20250504123045") or `nil` on HTTP error.
    static func getLatestTag() async throws -> String? {
        // GitHub REST API – latest release endpoint
        let url = URL(string: "https://api.github.com/repos/azooKey/azooKey_hotfix_dictionary_storage/releases/latest")!
        var request = URLRequest(url: url)
        // Use the recommended Accept header for the REST API v3
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        // Perform the request using async/await
        let (data, response) = try await URLSession.shared.data(for: request)

        // Ensure HTTP 200 OK
        guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
            return nil
        }

        // Decode only the "tag_name" field
        struct LatestRelease: Decodable { let tag_name: String }
        let latest = try JSONDecoder().decode(LatestRelease.self, from: data)
        return latest.tag_name
    }

    static var cachedTag: String? {
        UserDefaults.standard.string(forKey: "azooKey_hotfix_dictionary_storage_latest_tag")
    }
    static var lastCheckDate: Date? {
        guard let date = UserDefaults.standard.string(forKey: "azooKey_hotfix_dictionary_storage_last_check_date") else {
            return nil
        }
        return ISO8601DateFormatter().date(from: date)
    }
    static func setLastCheckDate() {
        UserDefaults.standard.set(ISO8601DateFormatter().string(from: Date()), forKey: "azooKey_hotfix_dictionary_storage_last_check_date")
    }

    static func checkUpdate() async throws -> (updated: Bool, latestTag: String?) {
        // Previously‑cached value (may be nil the first time)
        let latestTag: String? = try await getLatestTag()
        return (updated: cachedTag != latestTag, latestTag: latestTag)
    }

    static func update(latestTag: String) async throws {
        let release = "https://github.com/azooKey/azooKey_hotfix_dictionary_storage/releases/download/\(latestTag)/data_v1.json"
        let hotfixDictionary = try await HotfixDictionaryV1.load(from: URL(string: release)!)
        if hotfixDictionary.metadata.status == .active {
            // UserDefaults.standardに保存
            UserDefaults.standard.setValue(try JSONEncoder().encode(hotfixDictionary), forKey: "azooKey_hotfix_dictionary_storage")
        } else {
            // 削除
            UserDefaults.standard.removeObject(forKey: "azooKey_hotfix_dictionary_storage")
        }
        await MainActor.run {
            AdditionalDictManager().userDictUpdate()
        }
        // 最新タグを保存
        UserDefaults.standard.set(latestTag, forKey: "azooKey_hotfix_dictionary_storage_latest_tag")
    }

    static func updateIfRequired(ignoreFrequency: Bool = false) async throws {
        if !ignoreFrequency, let lastCheckDate, lastCheckDate.advanced(by: 24 * 60 * 60) > Date() {
            // この場合はアップデートはしない
            print("The last check has been performed within the last 24 hours.")
            return
        }
        let (requireUpdate, latestTag) = try await HotfixDictionaryV1.checkUpdate()
        if requireUpdate, let latestTag {
            try await HotfixDictionaryV1.update(latestTag: latestTag)
        } else {
            print("Skip update: requireUpdate: \(requireUpdate), latestTag: \(latestTag ?? "nil")")
        }
        // チェックは行ったので保存
        setLastCheckDate()
    }
}
