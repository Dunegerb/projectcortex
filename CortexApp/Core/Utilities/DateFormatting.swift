import Foundation

extension Date {
    var cortexShortDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }
}

extension Double {
    var cortexPercentage: String {
        "\(Int((self * 100).rounded()))%"
    }
}
