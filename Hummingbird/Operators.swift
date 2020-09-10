//
//  Operators.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 03/05/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


func +(a: CGPoint, b: CGPoint) -> CGPoint {
    return CGPoint(x: a.x + b.x, y: a.y + b.y)
}


func +(a: CGSize, b: CGPoint) -> CGSize {
    return CGSize(width: a.width + b.x, height: a.height + b.y)
}


func -(a: CGPoint, b: CGPoint) -> CGPoint {
    return CGPoint(x: a.x - b.x, y: a.y - b.y)
}


func +=(a: inout CGPoint, b: CGPoint) {
    a = a + b
}


func +=(a: inout CGSize, b: CGPoint) {
    a = a + b
}
