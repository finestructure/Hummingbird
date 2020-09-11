import Foundation


enum Corner: CustomStringConvertible {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft

    var description: String {
        switch self {
            case .topLeft:
                return "1️⃣"
            case .topRight:
                return "2️⃣"
            case .bottomRight:
                return "3️⃣"
            case .bottomLeft:
                return "4️⃣"
        }
    }

    static func corner(for position: CGPoint, in size: CGSize) -> Self {
        switch (position.x / size.width, position.y / size.height) {
            case let (x, y) where x < 0.5 && y < 0.5:
                return .topLeft
            case let (x, y) where x >= 0.5 && y < 0.5:
                return .topRight
            case let (x, y) where x >= 0.5 && y >= 0.5:
                return .bottomRight
            case let (x, y) where x < 0.5 && y >= 0.5:
                return .bottomLeft
            default:
                return .bottomRight
        }
    }
}
