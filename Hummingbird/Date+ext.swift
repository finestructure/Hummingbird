//
//  Date+ext.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 11/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


enum DateMask {
    case day

    var dateComponents: Set<Calendar.Component> {
        switch self {
        case .day:
            return [.year, .month, .day]
        }
    }
}


func truncate(date: Date, to mask: DateMask = .day) -> DateComponents {
    return Calendar.current.dateComponents(mask.dateComponents, from: date)
}


extension Date {
    static var now: Date { return Current.date() }
    func truncated(to mask: DateMask = .day) -> DateComponents {
        return truncate(date: self, to: mask)
    }
}


extension Date: Defaultable {
    static var defaultValue: Any {
        return Current.date()
    }

    init(forKey key: DefaultsKeys, defaults: UserDefaults) {
        guard
            let value = defaults.object(forKey: key.rawValue) as? Date
            else {
                self = Date.defaultValue as! Date
                return
        }
        self = value
    }

    func save(forKey key: DefaultsKeys, defaults: UserDefaults) throws {
        defaults.set(self, forKey: key.rawValue)
    }
}
