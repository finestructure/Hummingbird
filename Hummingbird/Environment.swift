//
//  World.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 15/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//
//  Motivation: https://www.pointfree.co/blog/posts/21-how-to-control-the-world
//

import Foundation


public struct Environment {
    public var environment = ProcessInfo.processInfo.environment
    public var date: () -> Date = { Date() }
    public var gumroad = Gumroad()
}


var Current = Environment()
