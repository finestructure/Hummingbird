//
//  History.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 08/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


struct History<T> {
    public let depth: DateComponents
    private var history: [DateComponents: T] = [:]
    init(depth: DateComponents) {
        self.depth = depth
    }
}

extension History {

    static var dateComponents: Set<Calendar.Component> { return [.year, .month, .day]}

    func truncate(date: Date) -> DateComponents {
        return Calendar.current.dateComponents(History.dateComponents, from: date)
    }

    var now: DateComponents { return truncate(date: Date()) }

    var cutoff: DateComponents? {
        guard let date = Calendar.current.date(byAdding: depth, to: Date()) else { return nil }
        return truncate(date: date)
    }

    var currentValue: T? {
        get {
            return history[now]
        }
        set {
            history[now] = newValue
        }
    }

    subscript(date: Date) -> T? {
        get {
            let truncated = truncate(date: date)
            return history[truncated]
        }
        set {
            let truncated = truncate(date: date)
            guard
                let c = cutoff,
                let cutoff = Calendar.current.date(from: c),
                let truncDate = Calendar.current.date(from: truncated)
                else { return }
            if truncDate >= cutoff {
                history[truncated] = newValue
            }
        }
    }

    var count: Int { return history.count }

}
