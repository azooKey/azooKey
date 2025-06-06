//
//  SharedStore.swift
//  azooKey
//
//  Created by ensan on 2020/11/20.
//  Copyright © 2020 ensan. All rights reserved.
//

import Foundation
import SwiftUtils

public enum SharedStore {
    @MainActor static let userDefaults = UserDefaults(suiteName: Self.appGroupKey)!
    public static let bundleName = "DevEn3.azooKey.keyboard"
    public static let appGroupKey = "group.com.azooKey.keyboard"

    private static var appVersionString: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    private static let initialAppVersionKey = "InitialAppVersion"
    private static let lastAppVersionKey = "LastAppVersion"
    public static var currentAppVersion: AppVersion? {
        if let appVersionString = appVersionString {
            return AppVersion(appVersionString)
        }
        return nil
    }
    // this value will be 1.7.1 at minimum
    @MainActor public static var initialAppVersion: AppVersion? {
        if let appVersionString = userDefaults.string(forKey: initialAppVersionKey) {
            return AppVersion(appVersionString)
        }
        return nil
    }

    // this value will be 2.0.0 at minimum
    @MainActor public static var lastAppVersion: AppVersion? {
        if let appVersionString = userDefaults.string(forKey: lastAppVersionKey) {
            return AppVersion(appVersionString)
        }
        return nil
    }

    @MainActor public static func setInitialAppVersion() {
        if initialAppVersion == nil, let appVersionString = appVersionString {
            SharedStore.userDefaults.set(appVersionString, forKey: initialAppVersionKey)
        }
    }

    @MainActor public static func setLastAppVersion() {
        if let appVersionString = appVersionString {
            SharedStore.userDefaults.set(appVersionString, forKey: lastAppVersionKey)
        }
    }

    public enum ShareThisWordOptions: String, Sendable {
        case 人・動物・会社などの名前
        case 場所・建物などの名前
        case 五段活用
    }

    public static func sendSharedWord(word: String, ruby: String, note: String? = nil, options: [ShareThisWordOptions]) async -> Bool {
        let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSceGtIHH8P-KbrB2ownprap3cUVVJegbhGekfz1xCiwPxBNfg/formResponse")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("no-cors", forHTTPHeaderField: "mode")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let importanceKey = 1129894332 // 重要度、1~5
        let wordKey = 813756984  // 単語、文字列
        let rubyKey = 688013311  // ルビ、文字列
        let categoryKey = 2110887544 // 品詞
        let noteKey = 1136445695  // 備考

        var parameters = "entry.\(importanceKey)=3&entry.\(wordKey)=\(word)&entry.\(rubyKey)=\(ruby.isEmpty ? "読み記入なし" : ruby)"

        let note = (note ?? "備考記入なし") + "\n" + "アプリ内フォームから送信" + "\n" + "azooKeyのバージョン: \(SharedStore.appVersionString ?? "不明")"
        parameters += "&entry.\(noteKey)=\(note)"

        parameters += "&entry.\(categoryKey)=__other_option__"
        let categoryInfo = options.map {$0.rawValue}.joined(separator: "、")
        parameters += "&entry.\(categoryKey).other_option_response=\(categoryInfo.isEmpty ? "品詞記入無し" : categoryInfo)"
        request.httpBody = parameters
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?
            .data(using: .utf8) ?? Data()
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            debug("sendSharedWord response", parameters, response)
            return true
        } catch {
            debug("sendSharedWord error", error)
            return false
        }
    }
}
