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


struct History<T: Initializable> {
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

    var currentValue: T {
        get {
            return history[now] ?? T()
        }
        set {
            history[now] = newValue
        }
    }

    subscript(date: Date) -> T {
        get {
            let truncated = truncate(date: date)
            return history[truncated] ?? T()
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

    private static var _defaultValue: History<Metrics> { return History<Metrics>(depth: DateComponents(day: -30)) }

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
