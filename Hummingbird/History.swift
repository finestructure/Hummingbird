//
//  History.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 08/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


protocol Initializable {
    init()
}


protocol Summable {
    static func +(a: Self, b: Self) -> Self
}


struct History<T: Initializable> {
    public let depth: DateComponents
    var history = OrderedDictionary<DateComponents, T>()
    var outDatedTotal: T
    var outdatedCount: Int = 0

    init(depth: DateComponents) {
        self.depth = depth
        self.outDatedTotal = T()
    }
}


extension History {

    static var mask: DateMask { return .day }

    var cutoff: Date? {
        guard
            let date = Calendar.current.date(byAdding: depth, to: Current.date()),
            let cutoffDate = Calendar.current.date(from: date.truncated(to: History.mask))
            else { return nil }
        return cutoffDate
    }

    var count: Int { return history.count }

}


extension History where T: Summable {

    var currentValue: T {
        get {
            return self[.now] ?? T()
        }
        set {
            self[.now] = newValue
        }
    }

    subscript(date: Date) -> T? {
        get {
            let truncated = date.truncated(to: History.mask)
            return history[truncated]
        }
        set {
            let truncated = date.truncated(to: History.mask)
            guard
                let cutoff = cutoff,
                let truncDate = Calendar.current.date(from: truncated)
                else { return }
            if truncDate >= cutoff {
                history[truncated] = newValue
            }
            while
                let h = history.first,
                let d = Calendar.current.date(from: h.key),
                d < cutoff {
                    if let outdated = history.removeValue(forKey: h.key) {
                        outDatedTotal = outDatedTotal + outdated
                        outdatedCount += 1
                    }
            }
        }
    }

}


extension History: Sequence {
    public struct Iterator: IteratorProtocol {
        public typealias Element = (key: DateComponents, value: T)
        var iterator: Dictionary<DateComponents, T>.Iterator

        init(_ iterator: Dictionary<DateComponents, T>.Iterator) {
            self.iterator = iterator
        }

        mutating public func next() -> Element? { return iterator.next() }
    }

    public func makeIterator() -> History.Iterator {
        return Iterator(history.makeIterator())
    }
}


extension History: Equatable where T: Equatable {}


extension History: Codable where T: Codable {}


extension History: Defaultable where T == Metrics {

    private static var _defaultValue: History<Metrics> { return History<Metrics>(depth: DateComponents(day: -1000)) }

    static var defaultValue: Any {
        return try! PropertyListEncoder().encode(History._defaultValue)
    }

    init(forKey key: DefaultsKeys, defaults: UserDefaults) {
        guard
            let data = defaults.data(forKey: key.rawValue),
            let decoded = try? PropertyListDecoder().decode(History<T>.self, from: data)
            else {
            self = History._defaultValue
            return
        }
        self = decoded
    }

    func save(forKey key: DefaultsKeys, defaults: UserDefaults) throws {
        let data = try PropertyListEncoder().encode(self)
        defaults.set(data, forKey: key.rawValue)
    }

}


// Stats methods
extension History {
    func max(by areInIncreasingOrder: ((DateComponents, T), (DateComponents, T)) throws -> Bool) rethrows -> (DateComponents, T)? {
        // FIXME: don't reach through
        return try history.dict.max(by: areInIncreasingOrder)
    }
}


extension History where T == Metrics {
    var total: T {
        // FIXME: don't reach through
        guard !history.dict.isEmpty else { return outDatedTotal }
        return history.dict.values.reduce(T(), +) + outDatedTotal
    }

    var average: T? {
        let n = history.count + outdatedCount
        guard n > 0 else { return nil }
        return total / CGFloat(n)
    }
}


extension History where T == Metrics {
    func isAverageMilestone(_ value: Metrics) -> Bool {
        guard let average = average else { return true }
        return value.distanceMoved > average.distanceMoved || value.areaResized > average.areaResized
    }
}
