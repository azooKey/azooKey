//
//  CustomKeysSettingView.swift
//  CustomKeysSettingView
//
//  Created by ensan on 2021/07/24.
//  Copyright © 2021 ensan. All rights reserved.
//

import KeyboardViews
import SwiftUI

struct CustomKeysSettingView: View {
    @EnvironmentObject private var appStates: MainAppStates

    private var settingAdaptive: Bool

    init(settingAdaptive: Bool = false) {
        self.settingAdaptive = settingAdaptive
    }

    private func canFlickLayout(_ layout: LanguageLayout) -> Bool {
        if layout == .flick {
            return true
        }
        if case .custard = layout {
            return true
        }
        return false
    }

    private func canQwertyLayout(_ layout: LanguageLayout) -> Bool {
        if layout == .qwerty {
            return true
        }
        return false
    }

    private func isCustard(_ layout: LanguageLayout) -> Bool {
        if case .custard = layout {
            return true
        }
        return false
    }

    var body: some View {
        let hasJapaneseFlick = self.canFlickLayout(appStates.japaneseLayout)
        let hasCustard = self.isCustard(appStates.japaneseLayout) || self.isCustard(appStates.englishLayout)
        let hasQwerty = self.canQwertyLayout(appStates.japaneseLayout) || self.canQwertyLayout(appStates.englishLayout)
        if hasJapaneseFlick || hasCustard || !self.settingAdaptive {
            ImageSlideshowView(pictures: [.flickCustomKeySetting0, .flickCustomKeySetting1, .flickCustomKeySetting2])
                .listRowSeparator(.hidden, edges: .bottom)
            Text("「小ﾞﾟ」キーと「､｡?!」キーで入力する文字をカスタマイズすることができます。")
            NavigationLink("設定する") {
                FlickCustomKeysSettingSelectView()
            }
            .foregroundStyle(.accentColor)
            .listRowSeparator(.visible, edges: .all)
        }
        if hasQwerty || !self.settingAdaptive {
            ImageSlideshowView(pictures: [.qwertyCustomKeySetting0, .qwertyCustomKeySetting1, .qwertyCustomKeySetting2])
                .listRowSeparator(.hidden, edges: .bottom)
            Text("数字タブの青枠部分に好きな記号や文字を割り当てられます。")
            NavigationLink("設定する") {
                QwertyCustomKeysSettingView(.numberTabCustomKeys)
            }
            .foregroundStyle(.accentColor)
            .listRowSeparator(.visible, edges: .all)
        }
    }
}
