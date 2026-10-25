import SwiftUI

public struct EditConfirmButton: View {
    public enum ConfirmationType: Sendable, Equatable {
        case save
        case done

        var label: LocalizedStringKey {
            switch self {
            case .save:
                "保存"
            case .done:
                "完了"
            }
        }
    }

    public init(_ type: ConfirmationType = .save, action: @escaping () -> Void) {
        self.confirmationType = type
        self.action = action
    }
    private var confirmationType: ConfirmationType
    private var action: () -> Void

    public var body: some View {
        if #available(iOS 26, macOS 26, *) {
            Button(self.confirmationType.label, systemImage: "checkmark", role: .confirm) {
                self.action()
            }
            .labelStyle(.iconOnly)
        } else {
            Button(self.confirmationType.label) {
                self.action()
            }
        }
    }
}

public struct EditCancelButton: View {
    public init(confirmationRequired: Bool = true, action: (() -> Void)? = nil) {
        self.confirmationRequired = confirmationRequired
        self.action = action
    }

    private let confirmationRequired: Bool
    private var action: (() -> Void)?

    @State private var showCancellationAlert: Bool = false
    @Environment(\.dismiss) private var dismiss

    private func cancel() {
        if let action {
            action()
        } else {
            self.dismiss()
        }
    }

    public var body: some View {
        if #available(iOS 26, macOS 26, *) {
            Button("キャンセル", systemImage: "xmark", role: .cancel) {
                if confirmationRequired {
                    self.showCancellationAlert = true
                } else {
                    self.cancel()
                }
            }
            .labelStyle(.iconOnly)
            .alert("編集を中止します。変更はすべて失われます。", isPresented: $showCancellationAlert) {
                Button("編集を中止する", role: .destructive, action: self.cancel)
            }
        } else {
            Button("キャンセル", role: .cancel) {
                if confirmationRequired {
                    self.showCancellationAlert = true
                } else {
                    self.dismiss()
                }
            }
            .alert("編集を中止します。変更はすべて失われます。", isPresented: $showCancellationAlert) {
                Button("編集を中止する", role: .destructive, action: self.cancel)
            }
        }
    }
}

public extension View {
    @ViewBuilder
    func verticalBarLabelStyle() -> some View {
        #if os(iOS) && compiler(>=6.4) && canImport(SwiftUI, _version: 8.0.85.29)
        if #available(iOS 27.1, *) {
            modifier(VerticalBarLabelStyle())
        } else {
            labelStyle(.titleOnly)
        }
        #else
        labelStyle(.titleOnly)
        #endif
    }
}

#if os(iOS) && compiler(>=6.4) && canImport(SwiftUI, _version: 8.0.85.29)
@available(iOS 27.1, *)
private struct VerticalBarLabelStyle: ViewModifier {
    @Environment(\.toolbarVerticalEdge) private var toolbarVerticalEdge

    func body(content: Content) -> some View {
        // 通常のバーは文字表示を保ち、縦に並ぶバーだけアイコンを使う。
        if toolbarVerticalEdge != nil {
            content.labelStyle(.iconOnly)
        } else {
            content.labelStyle(.titleOnly)
        }
    }
}
#endif
