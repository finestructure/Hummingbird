//
//  TrackingInfo.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 03/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


class TrackingInfo {
    var time: CFTimeInterval = 0
    var window: AXUIElement? = nil
    var start: CGPoint = .zero
    var origin: CGPoint = .zero
    var size: CGSize = .zero
    var distanceMoved: CGFloat = 0
    var areaResized: CGFloat = 0
    var corner: Corner = .bottomRight
    var aggregateDelta: Delta = .zero
}
