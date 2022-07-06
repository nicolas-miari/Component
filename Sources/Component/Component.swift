import Foundation

/**
 The common interface for all types of components.
 */
public protocol Component: Codable, Equatable {

  var type: String { get }
}

extension Component {
  static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.type == rhs.type
  }
}
