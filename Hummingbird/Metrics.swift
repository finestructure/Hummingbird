//
//  Metrics.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 03/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


struct Metrics: Equatable {
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
    static let scales = [
        (1.0, "k"),
        (2.0, "M"),
        (3.0, "G"),
        (4.0, "T"),
        (5.0, "P"),
    ]

    mutating func appendInterpolation(scaled value: Decimal) {
        let fmt = NumberFormatter()
        fmt.roundingMode = .halfUp
        fmt.minimumIntegerDigits = 1
        fmt.minimumFractionDigits = 1
        fmt.maximumFractionDigits = 1
        for (exp, postfix) in DefaultStringInterpolation.scales.reversed() {
            if value > Decimal(pow(1000, exp)) {
                fmt.multiplier = pow(1000, -exp) as NSNumber
                appendInterpolation(fmt.string(from: value as NSNumber).map { $0 + postfix } ?? "\(value)")
                return
            }
        }
        appendInterpolation(fmt.string(from: value as NSNumber) ?? "\(value)")
    }

    mutating func appendInterpolation(_ value: Metrics) {
        appendInterpolation("Distance: \(scaled: Decimal(Double(value.distanceMoved))), Area: \(scaled: Decimal(Double(value.areaResized)))")
    }
}


func areaDelta(a: CGSize, d: CGPoint) -> CGFloat {
    return (d.magnitude >= 0 ? d.x * d.y : 0) + abs(d.x) * a.height + a.width * abs(d.y)
}
