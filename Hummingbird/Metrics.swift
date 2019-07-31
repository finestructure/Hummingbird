//
//  Metrics.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 03/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


struct Metrics: Equatable, Codable {
    var distanceMoved: CGFloat = 0
    var areaResized: CGFloat = 0
}


extension Metrics: Initializable { }
extension Metrics: Summable { }


func areaDelta(a: CGSize, d: CGPoint) -> CGFloat {
    return (d.magnitude >= 0 ? d.x * d.y : 0) + abs(d.x) * a.height + a.width * abs(d.y)
}


func +(a: Metrics, b: Metrics) -> Metrics {
    return Metrics(distanceMoved: a.distanceMoved + b.distanceMoved, areaResized: a.areaResized + b.areaResized)
}


func /(a: Metrics, b: CGFloat) -> Metrics {
    return Metrics(distanceMoved: a.distanceMoved / b, areaResized: a.areaResized / b)
}
