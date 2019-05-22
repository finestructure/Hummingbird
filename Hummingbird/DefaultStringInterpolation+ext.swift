//
//  DefaultStringInterpolation+ext.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 22/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


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

    mutating func appendInterpolation(_ value: DateComponents) {
        if let date = Calendar.current.date(from: value) {
            let df = DateFormatter()
            df.dateStyle = .short
            appendInterpolation(df.string(from: date))
        }
    }

    mutating func appendInterpolation(distance: CGFloat) {
        appendInterpolation("\(scaled: Decimal(Double(distance))) pixels")
    }

    mutating func appendInterpolation(area: CGFloat) {
        appendInterpolation("\(scaled: Decimal(Double(area))) pixels²")
    }
}
