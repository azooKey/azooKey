//
//  ThemeEditView.swift
//  MainApp
//
//  Created by ensan on 2021/02/07.
//  Copyright © 2021 ensan. All rights reserved.
//

import AzooKeyUtils
import Foundation
import KeyboardThemes
import KeyboardViews
import PhotosUI
import SwiftUI
import SwiftUIUtils
import SwiftUtils

private struct ThemeColorTranslator: Intertranslator {
    typealias First = AzooKeyTheme.ColorData
    typealias Second = Color

    func convert(_ first: AzooKeyTheme.ColorData) -> Color {
        first.color
    }

    func convert(_ second: Color) -> AzooKeyTheme.ColorData {
        .color(second)
    }
}

private struct ThemeSpecialKeyColorTranslator: Intertranslator {
    typealias First = AzooKeyTheme.ColorData
    typealias Second = Color

    func convert(_ first: AzooKeyTheme.ColorData) -> Color {
        ThemeColorTranslator().convert(first)
    }

    func convert(_ second: Color) -> AzooKeyTheme.ColorData {
        if let keyColor = ColorTools.rgba(second, process: {r, g, b, opacity in
            Color(.displayP3, red: r, green: g, blue: b, opacity: max(0.001, opacity))
        }) {
            return .color(keyColor)
        }
        return .color(second)
    }
}

private struct ThemeNormalKeyColorTranslator: Intertranslator {
    typealias First = AzooKeyTheme.ColorData
    typealias Second = Color

    func convert(_ first: AzooKeyTheme.ColorData) -> Color {
        ThemeColorTranslator().convert(first)
    }

    func convert(_ second: Color) -> AzooKeyTheme.ColorData {
        if let keyColor = ColorTools.rgba(second, process: {r, g, b, opacity in
            Color(.displayP3, red: r, green: g, blue: b, opacity: max(0.001, opacity))
        }) {
            return .color(keyColor)
        }
        return .color(second)
    }
}

private struct ThemeFontDoubleTranslator: Intertranslator {
    typealias First = ThemeFontWeight
    typealias Second = Double

    func convert(_ first: First) -> Second {
        Double(first.rawValue)
    }

    func convert(_ second: Second) -> First {
        ThemeFontWeight(rawValue: Int(second)) ?? .regular
    }
}

struct ThemeEditView: CancelableEditor {
    @EnvironmentObject private var appStates: MainAppStates

    let base: AzooKeyTheme
    @State private var theme: AzooKeyTheme = .base
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Binding private var manager: ThemeIndexManager

    @State private var photosPickerItem: PhotosPickerItem?
    @State private var trimmedImage: UIImage?
    @State private var isTrimmingViewPresented = false
    @State private var pickedImage: UIImage?
    @State private var viewType = ViewType.editor

    private let colorConverter = ThemeColorTranslator()
    private let normalColorConverter = ThemeNormalKeyColorTranslator()
    private let specialColorConverter = ThemeSpecialKeyColorTranslator()

    private enum ViewType {
        case editor
        case themeShareView
    }

    private let title: LocalizedStringKey
    private var shareImage = ShareImage()

    init(index: Int?, manager: Binding<ThemeIndexManager>) {
        self._manager = manager
        if let index {
            do {
                var theme = try manager.wrappedValue.theme(at: index)
                theme.id = index
                self._theme = State(initialValue: theme)
                self.base = theme
            } catch {
                debug(error)
                self.base = .base
            }
            self.title = "着せ替えを編集"
        } else {
            self.base = .base
            self.title = "着せ替えを作成"
        }
        self.theme.suggestKeyFillColor = .color(.init(white: 1))
    }
    // PHPickerの設定
    private var config: PHPickerConfiguration {
        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
        config.filter = .images
        config.selectionLimit = 1
        return config
    }

    var body: some View {
        switch viewType {
        case .editor:
            VStack {
                Form {
                    Section(header: Text("背景")) {
                        if trimmedImage != nil {
                            PhotosPicker("\(systemImage: "photo")画像を選び直す", selection: $photosPickerItem)
                            Button("画像を削除") {
                                photosPickerItem = nil
                                pickedImage = nil
                                theme.picture = .none
                                trimmedImage = nil
                            }
                            .foregroundStyle(.red)
                        } else {
                            PhotosPicker("\(systemImage: "photo")画像を選ぶ", selection: $photosPickerItem)
                            ColorPicker("背景の色", selection: $theme.backgroundColor.converted(colorConverter))
                        }
                    }
                    Section(header: Text("文字")) {
                        HStack {
                            Text("文字の太さ")
                            Slider(value: $theme.textFont.converted(ThemeFontDoubleTranslator()), in: 1...9.9)
                        }
                    }

                    Section(header: Text("変換候補")) {
                        ColorPicker("変換候補の文字の色", selection: $theme.resultTextColor.converted(colorConverter))
                        ColorPicker("変換候補の背景色", selection: $theme.resultBackgroundColor.converted(colorConverter))
                    }

                    Section(header: Text("キー")) {
                        ColorPicker("キーの文字の色", selection: $theme.textColor.converted(colorConverter))
                        ColorPicker("通常キーの背景色", selection: $theme.normalKeyFillColor.converted(normalColorConverter))
                        ColorPicker("特殊キーの背景色", selection: $theme.specialKeyFillColor.converted(specialColorConverter))
                        ColorPicker("枠線の色", selection: $theme.borderColor.converted(colorConverter))
                        HStack {
                            Text("枠線の太さ")
                            Slider(value: $theme.borderWidth, in: 0...10)
                        }
                    }

                    Section {
                        Button("リセットする") {
                            self.pickedImage = nil
                            self.theme.picture = .none
                            self.trimmedImage = nil
                            self.theme = self.base
                        }
                        .foregroundStyle(.red)
                    }
                }
                let tab: KeyboardTab.ExistentialTab = {
                    switch appStates.japaneseLayout {
                    case .flick:
                        return .flick_hira
                    case .qwerty:
                        return .qwerty_hira
                    case let .custard(identifier):
                        return .custard((try? CustardManager.load().custard(identifier: identifier)) ?? .errorMessage)
                    }
                }()
                KeyboardPreview(theme: self.theme, defaultTab: tab)
            }
            .background(Color.secondarySystemBackground)
            .onChange(of: trimmedImage) { (_, value) in
                if let value {
                    self.theme.picture = .uiImage(value)
                    self.theme.backgroundColor = .color(.white.opacity(0))
                    self.theme.resultBackgroundColor = .color(.white.opacity(0))
                } else {
                    self.theme.picture = .none
                }
            }
            .onChange(of: theme.normalKeyFillColor) { (_, value) in
                if let pushedKeyColor = ColorTools.hsv(value.color, process: {h, s, v, opacity in
                    let base = (floor(v - 0.5) + 0.5) * 2
                    return Color(hue: h, saturation: s, brightness: v - base * 0.1, opacity: max(0.05, sqrt(opacity)))
                }) {
                    self.theme.pushedKeyFillColor = .color(pushedKeyColor)
                }
            }
            .onChange(of: self.photosPickerItem) { (_, item) in
                guard let item else {
                    return
                }
                Task {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        print("Image Data loaded \(data.count)")
                        if let uiImage = UIImage(data: data) {
                            print("UIImage loaded \(uiImage)")
                            self.pickedImage = uiImage.fixedOrientation()
                            self.isTrimmingViewPresented = true
                        }
                    }
                }
            }
            .navigationBarTitle(Text(self.title), displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: EditCancelButton(confirmationRequired: true),
                trailing: EditConfirmButton {
                    do {
                        try self.save()
                    } catch {
                        debug(error)
                    }
                    self.viewType = .themeShareView
                }
            )
            .navigationDestination(isPresented: $isTrimmingViewPresented) {
                Group {
                    TrimmingView(
                        uiImage: $pickedImage,
                        resultImage: $trimmedImage,
                        maxSize: CGSize(width: 1280, height: 720),
                        aspectRatio: CGSize(width: SemiStaticStates.shared.screenWidth, height: Design.keyboardScreenHeight(upsideComponent: nil, orientation: MainAppDesign.keyboardOrientation))
                    )
                }
            }
        case .themeShareView:
            ThemeShareView(theme: self.theme, shareImage: shareImage) {
                self.dismiss()
                appStates.requestReviewManager.shouldTryRequestReview = true
            }
            .navigationBarTitle(Text("完了"), displayMode: .inline)
            .navigationBarItems(leading: EmptyView(), trailing: EmptyView())
        }
    }

    func cancel() {
        // only for conformance
    }

    private func save() throws {
        // テーマを保存する
        let id = try manager.saveTheme(theme: self.theme)
        self.theme.id = id
        manager.select(at: id)
    }
}

extension UIImage {
    fileprivate func fixedOrientation() -> UIImage {
        if self.imageOrientation == .up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: self.size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? self
    }
}
