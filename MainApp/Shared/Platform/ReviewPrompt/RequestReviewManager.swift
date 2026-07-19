//
//  RequestReviewManager.swift
//  azooKey
//
//  Created by ensan on 2023/03/14.
//  Copyright © 2023 ensan. All rights reserved.
//

import Foundation

struct RequestReviewManager {
    var shouldTryRequestReview: Bool = false

    mutating func shouldRequestReview() -> Bool {
        self.shouldTryRequestReview = false
        if let lastDate = UserDefaults.standard.value(forKey: "last_reviewed_date") as? Date {
            if -lastDate.timeIntervalSinceNow < 3000000 {   // 最後に表示してから1ヶ月は再度表示しない
                return false
            }
        }

        // 1/5の確率で表示する
        let rand = Int.random(in: 0...4)

        if rand == 0 {
            UserDefaults.standard.set(Date(), forKey: "last_reviewed_date")
            return true
        }
        return false
    }
}
