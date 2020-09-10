import Foundation


struct Delta {
    var dx: CGFloat
    var dy: CGFloat

    var magnitude: CGFloat {
        sqrt(dx * dx + dy * dy)
    }
}


func +(a: CGPoint, delta: Delta) -> CGPoint {
    return CGPoint(x: a.x + delta.dx, y: a.y + delta.dy)
}


func +=(a: inout CGPoint, delta: Delta) {
    a = a + delta
}


func +(a: CGSize, delta: Delta) -> CGSize {
    return CGSize(width: a.width + CGFloat(delta.dx), height: a.height + CGFloat(delta.dy))
}


func +=(a: inout CGSize, delta: Delta) {
    a = a + delta
}
