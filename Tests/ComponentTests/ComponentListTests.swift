import XCTest
import simd

@testable import Component

final class ComponentListTests: XCTestCase {

  func testInitialComponentsIncluded() throws {
    // GIVEN:
    let transform = TransformComponent(local:simd_float4x4(rows: [
      simd_float4(1, 0, 0, 0),
      simd_float4(0, 3, 0, 0),
      simd_float4(0, 0, 5, 0),
      simd_float4(0, 0, 0, 7),
    ]))
    let rigidBody = RigidBodyComponent(mass: 6)

    // WHEN:
    let list = ComponentList([transform, rigidBody])

    // THEN:
    XCTAssertEqual(list.component(ofType: TransformComponent.self)?.local, transform.local)
    XCTAssertEqual(list.component(ofType: RigidBodyComponent.self)?.mass, rigidBody.mass)
  }

  func testAddComponents() {
    // GIVEN:
    var list = ComponentList()
    let rigidBody = RigidBodyComponent(mass: 6)
    let transform = TransformComponent()

    // WHEN:
    list.addComponents([rigidBody, transform])

    // THEN:
    XCTAssertEqual(list.component(ofType: RigidBodyComponent.self)?.mass, rigidBody.mass)
  }

  func testComponentCount() {
    // GIVEN:
    let list0 = ComponentList()
    let list1 = ComponentList([TransformComponent()])
    let list2 = ComponentList([RigidBodyComponent(mass: 1), SpriteComponent(imageName: "1", atlasName: "2")])

    // THEN:
    XCTAssertEqual(list0.count, 0)
    XCTAssertEqual(list1.count, 1)
    XCTAssertEqual(list2.count, 2)
  }

  func testRemoveAbsentComponent() {
    // GIVEN:
    var list = ComponentList()

    // WHEN:
    let transform = list.removeComponent(ofType: TransformComponent.self)

    // THEN:
    XCTAssertNil(transform)
  }

  func testAddRemoveComponent() {
    // GIVEN:
    var list = ComponentList()
    let rigidBody = RigidBodyComponent(mass: 6)

    // WHEN:
    list.addComponent(rigidBody)
    list.removeComponent(ofType: RigidBodyComponent.self)

    // THEN:
    XCTAssertNil(list.component(ofType: RigidBodyComponent.self))
  }

  func testEncodeDecodeListRecoverComponents() throws {

    // GIVEN:
    let transform = TransformComponent()
    let sprite = SpriteComponent(imageName: "Image 1", atlasName: "Atlas 1")
    let rigidBody = RigidBodyComponent(mass: 4)

    var list = ComponentList([transform, sprite, rigidBody])

    // WHEN:
    let encoder = JSONEncoder()
    let data = try encoder.encode(list)
    let recoveredList = try JSONDecoder().decode(ComponentList.self, from: data)
    let recoveredTransform = recoveredList.component(ofType: TransformComponent.self)
    let recoveredSprite = recoveredList.component(ofType: SpriteComponent.self)
    let recoveredRigidBody = recoveredList.component(ofType: RigidBodyComponent.self)

    // THEN:
    XCTAssertEqual(transform.local, recoveredTransform?.local)
    XCTAssertEqual(sprite.imageName, recoveredSprite?.imageName)
    XCTAssertEqual(sprite.atlasName, recoveredSprite?.atlasName)
    XCTAssertEqual(rigidBody.mass, recoveredRigidBody?.mass)
  }

  func testComponentCodingKey() throws {
    // GIVEN:
    let intValue = 7
    let intKey = ComponentCodingKey(intValue: intValue)
    let stringValue = "7"
    let stringKey = ComponentCodingKey(stringValue: stringValue)

    // THEN:
    XCTAssertEqual(intKey?.intValue, intValue)
    XCTAssertEqual(stringKey.stringValue, stringValue)
  }
}

// MARK: - Supporting Types

fileprivate class TransformComponent: KeyedComponent {
  static let codingKey = ComponentCodingKey(stringValue: "transform")
  var local: simd_float4x4
  init(local: simd_float4x4 = .identity) {
    self.local = local
  }
}

fileprivate class SpriteComponent: KeyedComponent {
  static let codingKey = ComponentCodingKey(stringValue: "sprite")
  var imageName: String
  var atlasName: String
  init(imageName: String, atlasName: String) {
    self.imageName = imageName
    self.atlasName = atlasName
  }
}

fileprivate class RigidBodyComponent: KeyedComponent {
  static let codingKey = ComponentCodingKey(stringValue: "rigidBody")
  var mass: Float
  init(mass: Float) {
    self.mass = mass
  }
}

extension simd_float4x4: Codable {
  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    try self.init(container.decode([SIMD4<Float>].self))
  }
  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode([columns.0,columns.1, columns.2, columns.3])
  }
}

extension simd_float4x4 {
  static var identity: simd_float4x4 {
    return simd_float4x4(rows: [
      simd_float4(1, 0, 0, 0),
      simd_float4(0, 1, 0, 0),
      simd_float4(0, 0, 1, 0),
      simd_float4(0, 0, 0, 1),
    ])
  }
}
