//
//  ContactAuthManager.swift
//  azooKey
//
//  Created by miwa on 2023/09/23.
//  Copyright © 2023 DevEn3. All rights reserved.
//

import Contacts
import Foundation

struct ContactAuthManager {
    let contactStore: CNContactStore = CNContactStore()
    var authState: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }

    func requestAuthForContact(callback: @escaping ((granted: Bool, error: (any Error)?)) -> Void) {
        // notDeterminedの場合のみ利用可能
        // deniedの場合は明示的に設定アプリを開いてもらう必要がある
        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            contactStore.requestAccess(for: .contacts) { (granted, error) in
                callback((granted, error))
            }
        }
    }
}
