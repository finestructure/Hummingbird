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


extension Metrics {
    init(defaults: UserDefaults) {
        let distance = CGFloat(defaults.double(forKey: DefaultsKeys.distanceMoved.rawValue))
        let area = CGFloat(defaults.double(forKey: DefaultsKeys.areaResized.rawValue))
        self = Metrics(distanceMoved: distance, areaResized: area)
    }

    func save(defaults: UserDefaults = defaults) {
        defaults.set(distanceMoved, forKey: DefaultsKeys.distanceMoved.rawValue)
        defaults.set(areaResized, forKey: DefaultsKeys.areaResized.rawValue)
    }
}


extension DefaultStringInterpolation {
    mutating func appendInterpolation(_ value: Metrics) {
        appendInterpolation("Distance: \(Int(value.distanceMoved)), Area: \(Int(value.areaResized))")
    }
}


func areaDelta(a: CGSize, d: CGPoint) -> CGFloat {
    return (d.magnitude >= 0 ? d.x * d.y : 0) + abs(d.x) * a.height + a.width * abs(d.y)
}
