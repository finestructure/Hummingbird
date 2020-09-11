import Foundation


struct Delta {
    var dx: CGFloat
    var dy: CGFloat

    var magnitude: CGFloat {
        sqrt(dx * dx + dy * dy)
    }

    static var zero: Self { .init(dx: 0, dy: 0) }
}


func +(a: CGPoint, delta: Delta) -> CGPoint {
    return CGPoint(x: a.x + delta.dx, y: a.y + delta.dy)
}


func +=(a: inout CGPoint, delta: Delta) {
    a = a + delta
}


func +(a: CGSize, delta: Delta) -> CGSize {
    return CGSize(width: a.width + delta.dx, height: a.height + delta.dy)
}


func -(a: CGSize, delta: Delta) -> CGSize {
    return CGSize(width: a.width - delta.dx, height: a.height - delta.dy)
}


func +=(a: inout CGSize, delta: Delta) {
    a = a + delta
}


func -=(a: inout CGSize, delta: Delta) {
    a = a - delta
}
