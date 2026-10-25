import SwiftUI

struct AdaptiveEditorView<Editor: View, Preview: View, Legacy: View>: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private let editor: Editor
    private let preview: Preview
    private let legacy: Legacy

    init(@ViewBuilder editor: () -> Editor, @ViewBuilder preview: () -> Preview, @ViewBuilder legacy: () -> Legacy) {
        self.editor = editor()
        self.preview = preview()
        self.legacy = legacy()
    }

    var body: some View {
        GeometryReader { geometry in
            #if compiler(>=6.4) && canImport(SwiftUI, _version: 8.0.85.29)
            if #available(iOS 27.1, *) {
                FoldAwareEditorLayout(
                    editor: editor, preview: preview, legacy: legacy,
                    hasDivision: !geometry.reservedRegions(kind: .division, options: .includeInactive).isEmpty,
                    compactHeight: verticalSizeClass == .compact
                )
            } else {
                fallback
            }
            #else
            fallback
            #endif
        }
    }

    @ViewBuilder
    private var fallback: some View {
        if verticalSizeClass == .compact {
            editor
        } else {
            legacy
        }
    }
}

#if compiler(>=6.4) && canImport(SwiftUI, _version: 8.0.85.29)
@available(iOS 27.1, *)
private struct FoldAwareEditorLayout<Editor: View, Preview: View, Legacy: View>: View {
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge
    let editor: Editor
    let preview: Preview
    let legacy: Legacy
    let hasDivision: Bool
    let compactHeight: Bool

    var body: some View {
        // 普通のiPhoneやiPadの配置まで変わらないよう、必要な画面だけ切り替えています。
        // 開ききると折り目が非アクティブになるので、その場合も含めて見ています。
        if hasDivision || toolbarVerticalEdge != nil || compactHeight {
            ArrangementView {
                editor.splitArrangementLayoutRatio(0.6)
            } secondary: {
                preview
            }
            .arrangementViewStyle(.split)
        } else {
            legacy
        }
    }
}
#endif
