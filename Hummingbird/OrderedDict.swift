//
//  OrderedDict.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 21/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


struct OrderedDictionary<K: Hashable, V> {
    var keys: [K] = []
    // FIXME: make dict private and add values
    var dict: [K: V] = [:]

    var count: Int {
        assert(keys.count == dict.count, "internal inconsistency")
        return keys.count
    }

    subscript(index: Int) -> V? {
        get {
            return dict[keys[index]]
        }
        set {
            let key = keys[index]
            if let newValue = newValue {
                dict[key] = newValue
            } else {
                // remove value at index
                keys.remove(at: index)
                dict.removeValue(forKey: key)
            }
        }
    }

    subscript(key: K) -> V? {
        get {
            return dict[key]
        }
        set {
            if let newValue = newValue {
                if dict.updateValue(newValue, forKey: key) == nil {
                    keys.append(key)
                }
            } else {
                let _ = removeValue(forKey: key)
            }
        }
    }

    mutating func insert(_ newElement: (key: K, value: V), at index: Int) {
        assert(!keys.contains(newElement.key), "cannot insert duplicate key")
        keys.insert(newElement.key, at: index)
        dict[newElement.key] = newElement.value
    }

    mutating func insert(_ newElement: (key: K, value: V), before key: K) {
        assert(!keys.contains(newElement.key), "cannot insert duplicate key")
        guard let index = keys.firstIndex(of: key)
            else { return } // throw instead?
        insert(newElement, at: index)
    }

    mutating func insert(_ newElement: (key: K, value: V), after key: K) {
        assert(!keys.contains(newElement.key), "cannot insert duplicate key")
        guard let index = keys.firstIndex(of: key)
            else { return } // throw instead?
        let next = keys.index(after: index)
        insert(newElement, at: next)
    }

    mutating func remove(at index: Int) -> (key: K, value: V) {
        let key = keys.remove(at: index)
        let value = dict.removeValue(forKey: key)!
        return (key, value)
    }

    mutating func removeValue(forKey key: K) -> V? {
        let value = dict[key]
        keys.removeAll(where: { $0 == key })
        dict.removeValue(forKey: key)
        return value
    }

    var first: (key: K, value: V)? {
        guard
            let key = keys.first,
            let value = dict[key] else { return nil }
        return (key: key, value: value)
    }

    var last: (key: K, value: V)? {
        guard
            let key = keys.last,
            let value = dict[key] else { return nil }
        return (key: key, value: value)
    }

    func makeIterator() -> Dictionary<K, V>.Iterator {
        return dict.makeIterator()
    }

}


extension OrderedDictionary: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (K, V)...) {
        self.init()
        for (key, value) in elements {
            self[key] = value
        }
    }
}


extension OrderedDictionary: Encodable where K: Encodable, V: Encodable {}
extension OrderedDictionary: Decodable where K: Decodable, V: Decodable {}
extension OrderedDictionary: Equatable where K: Equatable, V: Equatable {}
