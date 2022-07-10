import Foundation

/**
 A component set is much like a set in that it contains unordered, unique elements.

 The main differences with a normal set are that:
 1. All elements must be of types that conform to Component, and
 2. Not only must each element be unique, but also its type. That is, at most one element of each
 concrete component type can be present in the set at any time.

 Components need to be reference types, so that changes to a component are immediately visible
 anywhere there's a reference to it, and to enable hierarchical relationships between instances of
 components (whether the of same type or not). Because of this, copies of a component set (a value
 type) are always shallow: the elements in the copy are the same objects as in the original.
 */
public struct ComponentSet {

  private var elements: [any Component] = []

  // MARK: - Introspection

  public func containsElement<T: Component>(ofType type: T.Type) -> Bool {
    for element in elements {
      if element is T {
        print("Set contains element of type \(String(describing: type))")
        return true
      }
    }
    print("Set does NOT contains element of type \(String(describing: type))")
    return false
  }

  func element<T: Component>(ofType type: T.Type) -> T? {
    return elements.first { $0 is T } as? T
  }

  func canInsertElement<T: Component>(_ element: T) -> Bool {
    return !containsElement(ofType: type(of: element))
  }

  // MARK: - Modification

  /// Inserts the passed component if no other component of the same type is present yet, throws
  /// otherwise.
  mutating func insertElement<T: Component>(_ element: T) throws {
    guard canInsertElement(element) else {
      throw ComponentSetError.duplicateComponent
    }
    elements.append(element)
  }

  /// Removes the component of the specified type if present, throws an error otherwise.
  mutating func removeElement<T: Component>(ofType type: T.Type) throws -> T {
    guard let index = elements.firstIndex(where: { $0 is T }), let element = elements.remove(at: index) as? T else {
      throw ComponentSetError.componentOfTypeNotFound(name: String(describing: T.self))
    }
    return element
  }
}

// MARK: - Supporting Types

public enum ComponentSetError: LocalizedError {
  case duplicateComponent
  case componentOfTypeNotFound(name: String)
}
