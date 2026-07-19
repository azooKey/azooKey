//
//  ImageSlideShow.swift
//  MainApp
//
//  Created by ensan on 2020/11/21.
//  Copyright © 2020 ensan. All rights reserved.
//

import SwiftUI
import SwiftUIUtils

struct ImageSlideshowView: View {
    private let pictures: [ImageResource]
    init(pictures: [ImageResource]) {
        self.pictures = pictures
    }

    var body: some View {
        CenterAlignedView {
            TimelineView(.periodic(from: .now, by: 2.5)) { context in
                let selection = Int(context.date.timeIntervalSince1970 / 2.5) % pictures.count
                Image(pictures[selection])
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: MainAppDesign.imageMaximumWidth)
            }
        }
    }
}
