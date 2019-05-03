//
//  CGEvent+ext.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 03/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


extension CGEvent {

    var mouseDelta: CGPoint {
        let dx = CGFloat(getDoubleValueField(.mouseEventDeltaX))
        let dy = CGFloat(getDoubleValueField(.mouseEventDeltaY))
        return CGPoint(x: dx, y: dy)
    }

}
