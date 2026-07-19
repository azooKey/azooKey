//
//  FontPicker.swift
//  MainApp
//
//  Created by ensan on 2021/02/18.
//  Copyright © 2021 ensan. All rights reserved.
//

import SwiftUI
import SwiftUtils

struct FontPicker: UIViewControllerRepresentable {
    init(configuration: UIFontPickerViewController.Configuration, pickerResult: Binding<Font>, isPresented: Binding<Bool>) {
        self.configuration = configuration
        self._pickerResult = pickerResult
        self._isPresented = isPresented
    }

    private let configuration: UIFontPickerViewController.Configuration
    @Binding private var pickerResult: Font
    @Binding private var isPresented: Bool

    func makeUIViewController(context: Context) -> UIFontPickerViewController {
        let controller = UIFontPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIFontPickerViewController, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// PHPickerViewControllerDelegate => Coordinator
    class Coordinator: NSObject, UIFontPickerViewControllerDelegate {
        private let parent: FontPicker

        init(_ parent: FontPicker) {
            self.parent = parent
        }
        func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
            // attempt to read the selected font descriptor, but exit quietly if that fails
            guard let descriptor = viewController.selectedFontDescriptor else {
                return
            }
            debug((descriptor.fontAttributes[.family] as? String) ?? descriptor.postscriptName)
            self.parent.pickerResult = Font.custom((descriptor.fontAttributes[.family] as? String) ?? descriptor.postscriptName, size: 16, relativeTo: .body)
            self.parent.isPresented = false
        }
    }
}

struct FontPickView: View {
    @State private var isFontPickerPresented = false
    @State private var selectedFont: Font = .body

    @MainActor private var fontPickerConfig: UIFontPickerViewController.Configuration {
        let config = UIFontPickerViewController.Configuration()
        config.displayUsingSystemFont = false
        config.includeFaces = true
        return config
    }

    var body: some View {
        VStack {
            Button("フォントを選択") {
                isFontPickerPresented = true
            }
            Text(verbatim: "テキスト Text").font(selectedFont)
        }
        .sheet(isPresented: $isFontPickerPresented, content: {
            FontPicker(
                configuration: .init(),
                pickerResult: $selectedFont,
                isPresented: $isFontPickerPresented
            )
        })
    }
}
