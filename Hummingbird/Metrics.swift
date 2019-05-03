//
//  Metrics.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 03/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


struct Metrics {
    var distanceMoved: CGFloat = 0
    var areaResized: CGFloat = 0
}


func areaDelta(a: CGSize, d: CGPoint) -> CGFloat {
    return (d.magnitude >= 0 ? d.x * d.y : 0) + abs(d.x) * a.height + a.width * abs(d.y)
}
