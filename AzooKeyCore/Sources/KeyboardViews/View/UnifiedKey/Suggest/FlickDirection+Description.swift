import enum CustardKit.FlickDirection

extension FlickDirection: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .left:
            return "左"
        case .top:
            return "上"
        case .right:
            return "右"
        case .bottom:
            return "下"
        }
    }
}
