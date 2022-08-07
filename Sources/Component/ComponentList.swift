//
//  File.swift
//  
//
//  Created by Nicolás Miari on 2022/08/07.
//

import Foundation

// MARK: - List

public struct ComponentList: Codable {

  private var components: [ComponentCodingKey: any KeyedComponent] = [:]

  /**
   Creates a list with the passed array of components.
   */
  public init(_ components: [any KeyedComponent] = []) {
    components.forEach {
      addComponent($0)
    }
  }

  public mutating func addComponent<T: KeyedComponent>(_ component: T) {
    self.components[T.codingKey] = component
    if(Self.encoderBlocks[T.codingKey] == nil) {
      Self.register(type: T.self)
    }
  }

  public mutating func addComponents(_ components: [any KeyedComponent]) {
    components.forEach { component in
      addComponent(component)
    }
  }

  public func component<T: KeyedComponent>(ofType type: T.Type) -> T? {
    return components[T.codingKey] as? T
  }

  @discardableResult
  public mutating func removeComponent<T: KeyedComponent>(ofType type: T.Type) -> T? {
    guard let component = components[T.codingKey] as? T else {
      return nil
    }
    self.components[T.codingKey] = nil
    return component
  }

  public var count: Int {
    return components.count
  }

  public func map<T>(_ transform: (any KeyedComponent) throws -> T) rethrows -> [T] {
    return try components.values.map(transform)
  }

  public func forEach(_ body: (KeyedComponent) throws -> Void) rethrows {
    try components.values.forEach(body)
  }

  public func component<T: KeyedComponent>(matchingTypeOf referenceComponent: T) -> T? {
    return components[T.codingKey] as? T
  }

  /**
   Returns an unsorted array of all the components.

   Use when component order is not important (should be faster than `sortedComponents`).
   */
  var allComponents: [any KeyedComponent] {
    return Array(components.values)
  }

  /**
   Returns an array of all the components, sorted alphabetically by the string value of their types'
   conding keys.
   */
  var sortedComponents: [any KeyedComponent] {
    let sortedKeys = components.keys.sorted { $0.stringValue < $1.stringValue }
    let values = sortedKeys.compactMap { components[$0] }
    return Array(values)
  }

  // MARK: - Codable

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: ComponentCodingKey.self)

    try Self.decoderBlocks.forEach { (key, decoderBlock) in
      self.components[key] = try decoderBlock(container)
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: ComponentCodingKey.self)

    try components.forEach { (key, component) in
      if let encoderBlock = Self.encoderBlocks[key] {
        try encoderBlock(component, &container)
      }
    }
  }

  // MARK: - Heterogeneous Serialization Support

  private typealias ComponentDecoderBlock = (KeyedDecodingContainer<ComponentCodingKey>) throws -> KeyedComponent?
  private typealias ComponentEncoderBlock = (KeyedComponent, inout KeyedEncodingContainer<ComponentCodingKey>) throws -> Void

  private static var decoderBlocks: [ComponentCodingKey: ComponentDecoderBlock] = [:]
  private static var encoderBlocks: [ComponentCodingKey: ComponentEncoderBlock] = [:]

  /**
   Registers a custom KeyedComponent-conforming type for encoding and decoding.

   Before decoding a component list from stored data, call this method once with each type you
   expect to encounter in the encoded representation. Because Codable does not support homogeneous
   collections out of the box, only types registered in advance can be detected in the read data.

   When adding components to a list instance, this method is called automatically for each new type,
   so encoding works automatically.
   */
  public static func register<T:KeyedComponent>(type: T.Type) {
    decoderBlocks[type.codingKey] = { container in
      let component = try container.decodeIfPresent(T.self, forKey: T.codingKey)
      return component
    }
    encoderBlocks[type.codingKey] = { (component: KeyedComponent, container) in
      try container.encode(component, forKey: T.codingKey)
    }
  }
}

// MARK: - Supporting Types and Extensions

/**
 Custom coding key type for coding components within heterogeneous collections.

 An alternative, simpler implementaton would have been to add `CodingKey` conformance `String` and
 use that instead of defining a new type. But this approach is more semantic, and avoids overloading
 the meaning of the `String` type which, in pronciple, can hold any kind of data.
 */
public struct ComponentCodingKey: CodingKey, Hashable {

  // MARK: - CodingKey

  private let rawValue: String

  public var stringValue: String {
    return rawValue
  }

  public var intValue: Int? {
    return Int(rawValue)
  }

  public init?(intValue: Int) {
    self.init(stringValue: "\(intValue)")
  }

  public init(stringValue: String) {
    self.rawValue = stringValue
  }

  // MARK: - Hashable

  public func hash(into hasher: inout Hasher) {
    rawValue.hash(into: &hasher)
  }
}

/**
 Adds support for coding a component within a heterogenous collection.
 */
public protocol KeyedComponent: Component {
  /**
   Key used to encode/decode a unique instance of the concrete type within a codable, heterogeneous
   collection of components.

   A default implementation is provided that generates the key based on the concrete type name.
   */
  static var codingKey: ComponentCodingKey { get }
}

extension KeyedComponent {

  public static var codingKey: ComponentCodingKey {
    let typeName = String(describing: Self.self)
    let camel = typeName.prefix(1).lowercased() + typeName.dropFirst()
    return ComponentCodingKey(stringValue: camel)
  }
}
