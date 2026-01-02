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

    public init(_ type: ConfirmationType = .save, action: @escaping () -> ()) {
        self.confirmationType = type
        self.action = action
    }
    private var confirmationType: ConfirmationType
    private var action: () -> ()

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
    public init(confirmationRequired: Bool = true, action: (() -> ())? = nil) {
        self.confirmationRequired = confirmationRequired
        self.action = action
    }

    private let confirmationRequired: Bool
    private var action: (() -> ())?

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
