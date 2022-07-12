import Foundation

/**
 A component set is much like a `Set` in that it contains unordered, unique elements.

 The main differences with a normal set are that:
 1. All elements must be of types that conform to Component, and
 2. Not only must each element be unique, but also its type. That is, at most one element of each
 concrete component type can be present in the set at any time.

 Components need to be reference types, so that changes to a component are immediately visible
 anywhere there's a reference to it, and to enable hierarchical relationships between instances of
 components (whether the of same type or not). Because of this, copies of a component set (a value
 type) are always shallow: the elements in the copy are the same objects as in the original.

 TODO(nicolas-miari): Consider renaming 'element' to 'component' everywhere in the public interface.
 */
public struct ComponentSet {

  // MARK: - Internal Storage

  /**
   The actual storage is just a plain, heterogeneous array components. The uniqueness of each stored
   element is guaranteed by the uniqueness of type, and that is in turn guarded by the insert
   method's implementation.
   */
  private var elements: [any Component] = []

  // MARK: - Introspection

  /**
   Returns `true` if the set contains a component of the specified type.
   */
  public func containsElement<T: Component>(ofType type: T.Type) -> Bool {
    for element in elements {
      if element is T {
        return true
      }
    }
    return false
  }

  /**
   Returns the (at most one) element of the specified type, or `nil` if none is present in the set.
   */
  public func element<T: Component>(ofType type: T.Type) -> T? {
    return elements.first { $0 is T } as? T
  }

  /**
   Returns `true` if the set does not contain a component of the same type as the argument.
   */
  public func canInsertElement<T: Component>(_ element: T) -> Bool {
    return !containsElement(ofType: type(of: element))
  }

  // MARK: - Modification

  /**
   Attempts to insert the specified component into the set. If a component of the same type is
   already present, `ComponentSetError.duplicateComponent` is thrown.
   */
  public mutating func insertElement<T: Component>(_ element: T) throws {
    guard canInsertElement(element) else {
      throw ComponentSetError.duplicateComponent
    }
    elements.append(element)
  }

  /**
   Attempts to remove the single component of the sepcified type. If none is present in the set,
   `ComponentSetError.componentOfTypeNotFound` and the name of the missing type is passed in the
   error's associated value.
   */
  public mutating func removeElement<T: Component>(ofType type: T.Type) throws -> T {
    guard let index = elements.firstIndex(where: { $0 is T }), let element = elements.remove(at: index) as? T else {
      throw ComponentSetError.componentOfTypeNotFound(name: String(describing: T.self))
    }
    return element
  }
}

// MARK: - Supporting Types

/**
 Error constants throwsn by the various methods of the `ComponentSet` public interface.
 */
public enum ComponentSetError: LocalizedError {
  /**
   An operation was attempted that would result in the set containing more than one component of the
   same type.
   */
  case duplicateComponent

  /**
   An element of type not present in the set was requested. The name of the type in question is
   returned in the String associated value.
   */
  case componentOfTypeNotFound(name: String)
}
