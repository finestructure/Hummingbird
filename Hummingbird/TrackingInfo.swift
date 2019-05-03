//
//  TrackingInfo.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 03/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


class TrackingInfo {
    var time: CFTimeInterval
    var window: AXUIElement?
    var origin: CGPoint
    var size: CGSize

    init() {
        self.time = 0
        self.window = nil
        self.origin = CGPoint.zero
        self.size = CGSize.zero
    }
}
