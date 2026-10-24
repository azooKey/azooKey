import SwiftUI

/// Primary contains every editing action, so compact presentations never lose
/// features when the system hides the optional visual preview.
struct AdaptiveEditorView<Editor: View, Preview: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let editor: Editor
    private let preview: Preview

    init(@ViewBuilder editor: () -> Editor, @ViewBuilder preview: () -> Preview) {
        self.editor = editor()
        self.preview = preview()
    }

    var body: some View {
        #if compiler(>=6.4) && canImport(SwiftUI, _version: 8.0.85.29)
        if #available(iOS 27.1, *) {
            ArrangementView {
                editor
                    .splitArrangementLayoutRatio(0.6)
            } secondary: {
                preview
            }
            .arrangementViewStyle(.split)
        } else {
            fallback
        }
        #else
        fallback
        #endif
    }

    private var fallback: some View {
        GeometryReader { geometry in
            if horizontalSizeClass == .regular && geometry.size.width >= 700 {
                HStack(spacing: 0) {
                    editor
                    preview
                }
            } else {
                editor
            }
        }
    }
}
