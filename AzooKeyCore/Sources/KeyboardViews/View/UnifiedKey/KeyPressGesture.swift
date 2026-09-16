import SwiftUI

struct KeyPressValue {
    var time: Date
    var startLocation: CGPoint
    var location: CGPoint

    init(_ value: DragGesture.Value) {
        time = value.time
        startLocation = value.startLocation
        location = value.location
    }

    init(time: Date, startLocation: CGPoint, location: CGPoint) {
        self.time = time
        self.startLocation = startLocation
        self.location = location
    }
}

@MainActor
struct KeyPressHandlers {
    var onChanged: (KeyPressValue) -> Void
    var onEnded: () -> Void
}

@MainActor
struct KeyPressGestureModifier: ViewModifier {
    var flick: KeyPressHandlers
    var linear: KeyPressHandlers
    var onCancelled: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 27.0, *) {
            content.gesture(ImmediateKeyGesture(
                onChanged: { value in
                    flick.onChanged(value)
                    linear.onChanged(value)
                },
                onEnded: {
                    flick.onEnded()
                    linear.onEnded()
                },
                onCancelled: onCancelled
            ))
        } else {
            legacyGesture(content: content)
        }
        #else
        legacyGesture(content: content)
        #endif
    }

    private func legacyGesture(content: Content) -> some View {
        content.gesture(
            DragGesture(minimumDistance: .zero, coordinateSpace: .global)
                .onChanged { flick.onChanged(KeyPressValue($0)) }
                .onEnded { _ in flick.onEnded() }
                .simultaneously(with:
                    DragGesture(minimumDistance: .zero)
                        .onChanged { linear.onChanged(KeyPressValue($0)) }
                        .onEnded { _ in linear.onEnded() }
                )
        )
    }
}

#if os(iOS)
import UIKit

// iOS 27 can defer the first zero-distance DragGesture update while system
// gestures arbitrate a stationary touch. Start the existing key lifecycle from
// UIKit touch delivery instead; the configured long-press duration stays intact.
@available(iOS 18.0, *)
struct ImmediateKeyGesture: UIGestureRecognizerRepresentable {
    var onChanged: (KeyPressValue) -> Void
    var onEnded: () -> Void
    var onCancelled: () -> Void

    func makeUIGestureRecognizer(context: Context) -> Recognizer {
        let recognizer = Recognizer()
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        updateUIGestureRecognizer(recognizer, context: context)
        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: Recognizer, context: Context) {
        recognizer.onChanged = onChanged
        recognizer.onEnded = onEnded
        recognizer.onCancelled = onCancelled
    }

    // Target/action delivery can itself wait for another recognizer to fail.
    // The touch callbacks below deliver each phase directly, including cancellation.
    func handleUIGestureRecognizerAction(_ recognizer: Recognizer, context: Context) {}

    final class Recognizer: UIGestureRecognizer {
        var onChanged: ((KeyPressValue) -> Void)?
        var onEnded: (() -> Void)?
        var onCancelled: (() -> Void)?
        private var trackedTouch: UITouch?
        private var startLocation: CGPoint = .zero

        // Observe the key's touch without preventing other recognizers.
        override func canPrevent(_ other: UIGestureRecognizer) -> Bool { false }
        override func canBePrevented(by other: UIGestureRecognizer) -> Bool { false }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            guard trackedTouch == nil, let touch = touches.first else {
                return
            }
            trackedTouch = touch
            startLocation = touch.location(in: nil)
            onChanged?(KeyPressValue(time: Date(), startLocation: startLocation, location: startLocation))
            state = .began
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
            guard let touch = trackedTouch, touches.contains(touch) else {
                return
            }
            onChanged?(KeyPressValue(time: Date(), startLocation: startLocation, location: touch.location(in: nil)))
            state = .changed
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            guard let touch = trackedTouch, touches.contains(touch) else {
                return
            }
            trackedTouch = nil
            onEnded?()
            state = .ended
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
            guard let touch = trackedTouch, touches.contains(touch) else {
                return
            }
            cancel()
            state = .cancelled
        }

        override func reset() {
            cancel()
            super.reset()
        }

        private func cancel() {
            guard trackedTouch != nil else {
                return
            }
            trackedTouch = nil
            onCancelled?()
        }
    }
}

#endif
