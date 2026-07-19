//
//  TrimmingView.swift
//  MainApp
//
//  Created by ensan on 2021/02/10.
//  Copyright © 2021 ensan. All rights reserved.
//

import Foundation
import SwiftUI
import SwiftUIUtils

private struct TrimmingState: Sendable, Equatable, Hashable {
    var initialScale: CGFloat = 1
    var frameSize: CGSize = .zero
}

private struct TrimmingStateKey: PreferenceKey {
    static func reduce(value: inout TrimmingState, nextValue: () -> TrimmingState) {
        value = nextValue()
    }
    static let defaultValue = TrimmingState()
}

struct TrimmingView: View {
    @Environment(\.dismiss) private var dismiss

    private let maxSize: CGSize
    private let aspectRatio: CGSize

    @State private var magnify: CGFloat = 1
    @State private var lastMagnify: CGFloat = 1
    @State private var angle: Angle = .degrees(.zero)
    @State private var lastAngle: Angle = .degrees(.zero)
    @State private var position: CGPoint = .zero
    @State private var lastPosition: CGPoint = .zero
    @State private var model = TrimmingState()
    private let imageSize: CGSize
    private let imageAspectRatio: CGFloat

    @Binding private var uiImage: UIImage?
    @Binding private var resultImage: UIImage?

    init(uiImage: Binding<UIImage?>, resultImage: Binding<UIImage?>, maxSize: CGSize, aspectRatio: CGSize) {
        self.maxSize = maxSize
        self.aspectRatio = aspectRatio
        self._resultImage = resultImage
        self._uiImage = uiImage

        self.imageSize = if let uiImage = uiImage.wrappedValue {
            uiImage.cgImage.flatMap {
                CGSize(width: $0.width, height: $0.height)
            } ?? CGSize(width: uiImage.size.width * uiImage.scale, height: uiImage.size.height * uiImage.scale)
        } else {
            CGSize.zero
        }
        self.imageAspectRatio = imageSize.width / imageSize.height
    }

    private func fitratio(screenSize: CGSize) -> CGFloat {
        if self.imageAspectRatio < screenSize.width / screenSize.height {
            return screenSize.height / imageSize.height
        } else {
            return screenSize.width / imageSize.width
        }
    }

    private func getModel(screenSize: CGSize) -> TrimmingState {
        var model = TrimmingState()
        let ratio: CGFloat = 1
        let height = screenSize.width * aspectRatio.height / aspectRatio.width
        if height > screenSize.height {
            let width = screenSize.height * aspectRatio.width / aspectRatio.height
            model.frameSize = CGSize(width: width * ratio, height: screenSize.height * ratio)
        } else {
            model.frameSize = CGSize(width: screenSize.width * ratio, height: height * ratio)
        }

        if self.imageAspectRatio <= self.aspectRatio.width / self.aspectRatio.height {
            model.initialScale = model.frameSize.width / imageSize.width
        } else {
            model.initialScale = model.frameSize.height / imageSize.height
        }

        return model
    }

    private func updateResult() {
        guard let cgImage = uiImage?.cgImage else {
            return
        }
        let scale = model.initialScale * magnify
        let size = CGSize(
            width: model.frameSize.width / scale,
            height: model.frameSize.height / scale
        )
        let originPosition = CGPoint(
            x: imageSize.width / 2 - (size.width / 2 + position.x / scale),
            y: imageSize.height / 2 - (size.height / 2 + position.y / scale)
        )
        if let crop = cgImage.cropping(to: CGRect(origin: originPosition, size: size)),
           let result = UIImage(cgImage: crop).scaled(fit: self.maxSize) {
            self.resultImage = result
        }
    }

    private func getRatioAndSize(geometry: GeometryProxy) -> (CGFloat, CGSize, TrimmingState) {
        let ratio = self.fitratio(screenSize: geometry.size) // scaledToFitによる縮小比
        let model = self.getModel(screenSize: geometry.size) // フレームのサイズ
        return (ratio, model.frameSize, model)
    }

    var body: some View {
        VStack {
            ZStack {
                GeometryReader {geometry in
                    let (ratio, size, currentModel) = self.getRatioAndSize(geometry: geometry)
                    Color.black
                    if let cgImage = uiImage?.cgImage {
                        Group {
                            // 画像の縦に対する横の長さが、フレームの縦に対する横の長さよりも小さい場合
                            if self.imageAspectRatio <= self.aspectRatio.width / self.aspectRatio.height {
                                Image(uiImage: UIImage(cgImage: cgImage))
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(size.width / (imageSize.width * ratio))
                            } else {
                                Image(uiImage: UIImage(cgImage: cgImage))
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(size.height / (imageSize.height * ratio))
                            }
                        }
                        .scaleEffect(self.magnify)
                        .rotationEffect(self.angle)
                        .position(x: self.position.x + geometry.size.width / 2, y: self.position.y + geometry.size.height / 2)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { v in
                                    let newValue = self.lastMagnify * v
                                    if 1 <= newValue && newValue <= 10 {
                                        self.magnify = newValue
                                    }
                                }
                                .onEnded { _ in
                                    self.lastMagnify = self.magnify
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { v in
                                    self.position = CGPoint(
                                        x: self.lastPosition.x + v.translation.width,
                                        y: self.lastPosition.y + v.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    self.lastPosition = self.position
                                }
                        )
                        .preference(key: TrimmingStateKey.self, value: currentModel)
                    }
                    Path {path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: 0, y: 0))

                        let dx = geometry.size.width / 2
                        let dy = geometry.size.height / 2
                        path.move(to: CGPoint(x: -size.width / 2 + dx, y: -size.height / 2 + dy))
                        path.addLine(to: CGPoint(x: -size.width / 2 + dx, y: size.height / 2 + dy))
                        path.addLine(to: CGPoint(x: size.width / 2 + dx, y: size.height / 2 + dy))
                        path.addLine(to: CGPoint(x: size.width / 2 + dx, y: -size.height / 2 + dy))
                        path.addLine(to: CGPoint(x: -size.width / 2 + dx, y: -size.height / 2 + dy))
                    }.fill(Color.black.opacity(0.5)).allowsHitTesting(false)

                    Rectangle()
                        .stroke(Color.white, lineWidth: 1.5)
                        .frame(width: size.width, height: size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
        .onPreferenceChange(TrimmingStateKey.self) { value in
            Task { @MainActor in
                self.model = value
            }
        }
        .onChange(of: magnify) { (_, value) in
            validation(magnifyValue: value, positionValue: position)
        }
        .onChange(of: position) { (_, value) in
            validation(magnifyValue: magnify, positionValue: value)
        }
        .navigationBarTitle(Text("画像をトリミング"), displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(trailing: EditConfirmButton(.done) {
            updateResult()
            self.dismiss()
        })

    }

    private func validation(magnifyValue: CGFloat, positionValue: CGPoint) {
        // 最も基本的な状態
        let scale = model.initialScale * magnify

        var change_x: CGFloat?
        var change_y: CGFloat?

        // 左のはみ出し
        if positionValue.x > (imageSize.width * scale - model.frameSize.width) / 2 {
            change_x = (imageSize.width * scale - model.frameSize.width) / 2
        }
        // 左のはみ出し
        if positionValue.y > (imageSize.height * scale - model.frameSize.height) / 2 {
            change_y = (imageSize.height * scale - model.frameSize.height) / 2
        }

        // →のはみ出し
        if positionValue.x < (-imageSize.width * scale + model.frameSize.width) / 2 {
            change_x = (-imageSize.width * scale + model.frameSize.width) / 2
        }
        // →のはみ出し
        if positionValue.y < (-imageSize.height * scale + model.frameSize.height) / 2 {
            change_y = (-imageSize.height * scale + model.frameSize.height) / 2
        }
        if let x = change_x,
           let y = change_y {
            position = CGPoint(x: x, y: y)
        } else if let x = change_x {
            position.x = x
        } else if let y = change_y {
            position.y = y
        }

    }

}

extension UIImage {
    fileprivate func scaled(fit maxSize: CGSize) -> UIImage? {
        if size.width < maxSize.width && size.height < maxSize.height {
            return self
        }
        let r_w = size.width / maxSize.width
        let r_h = size.height / maxSize.height
        let r = max(r_w, r_h)
        let canvasSize = CGSize(width: size.width / r, height: size.height / r)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        self.draw(in: CGRect(origin: .zero, size: canvasSize))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIImage.Orientation: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .down: return "down"
        case .downMirrored: return "downMirrored"
        case .left: return "left"
        case .leftMirrored: return "leftMirrored"
        case .right: return "right"
        case .rightMirrored: return "rightMirrored"
        case .up: return "up"
        case .upMirrored: return "upMirrored"
        @unknown default: return "unknown"
        }
    }
}
