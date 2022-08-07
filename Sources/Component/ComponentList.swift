//
//  File.swift
//  
//
//  Created by Nicolás Miari on 2022/08/07.
//

import Foundation

// MARK: - List

public struct ComponentList: Codable {

  private var components: [ComponentCodingKey: any Component] = [:]

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

  private typealias ComponentDecoderBlock = (KeyedDecodingContainer<ComponentCodingKey>) throws -> Component?
  private typealias ComponentEncoderBlock = (Component, inout KeyedEncodingContainer<ComponentCodingKey>) throws -> Void

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
    encoderBlocks[type.codingKey] = { (component, container) in
      try container.encode(component, forKey: T.codingKey)
    }
  }
}

// MARK: - Supporting Types and Extensions

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

public protocol KeyedComponent: Component {
  static var codingKey: ComponentCodingKey { get }
}
