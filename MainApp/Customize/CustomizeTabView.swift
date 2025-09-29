//
//  CustomizeTabView.swift
//  MainApp
//
//  Created by ensan on 2021/02/21.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import StoreKit
import SwiftUI
import SwiftUIUtils

struct CustomizeTabView: View {
    enum Path: Hashable {
        case information(String)
        case zenzaiSettings
    }

    @EnvironmentObject private var appStates: MainAppStates
    @Environment(\.requestReview) var requestReview
    @State private var path: [Path] = []

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                Form {
                    Section(header: Text("カスタムタブ")) {
                        ImageSlideshowView(pictures: [.custard1, .custard2, .custard3])
                            .listRowSeparator(.hidden, edges: .bottom)
                        Text("好きな文字や文章を並べたオリジナルのタブを作成することができます。")
                        NavigationLink("カスタムタブの管理") {
                            ManageCustardView(manager: $appStates.custardManager, path: $path)
                        }
                        .foregroundStyle(.accentColor)
                        NavigationLink("定型文タブを作る") {
                            EditingScrollCustardView(manager: $appStates.custardManager, path: $path)
                        }
                        .foregroundStyle(.accentColor)
                        NavigationLink("カスタムタブを作る") {
                            EditingGridFitCustardView(manager: $appStates.custardManager, path: $path)
                        }
                        .foregroundStyle(.accentColor)
                    }

                    Section(header: Text("タブバー")) {
                        CenterAlignedView {
                            Image(.tabBar1)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: MainAppDesign.imageMaximumWidth)
                        }
                        .listRowSeparator(.hidden, edges: .bottom)
                        Text("カスタムタブを使うにはタブバーを利用します。")
                        DisclosureGroup("使い方") {
                            Text("あずきのマークを押すと表示されます。")
                            Text("フリック入力では左上の「☆123」・ローマ字入力では左下の「123」「#+=」キーを長押ししても表示されます。")
                        }
                        NavigationLink("タブバーを編集") {
                            EditingTabBarView(manager: $appStates.custardManager)
                        }
                        .foregroundStyle(.accentColor)
                    }

                    Section(header: Text("カスタムキー")) {
                        CustomKeysSettingView()
                    }
                }
                .navigationBarTitle(Text("拡張"), displayMode: .large)
                .onAppear {
                    if appStates.requestReviewManager.shouldTryRequestReview, appStates.requestReviewManager.shouldRequestReview() {
                        requestReview()
                    }
                }
                .navigationDestination(for: Path.self) { destination in
                    switch destination {
                    case let .information(identifier):
                        if let custard = try? appStates.custardManager.custard(identifier: identifier) {
                            CustardInformationView(custard: custard, path: $path)
                        }
                    case .zenzaiSettings:
                        ZenzaiSettingView()
                    }
                }
            }
        }
    }
}
