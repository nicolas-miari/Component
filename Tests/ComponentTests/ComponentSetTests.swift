import XCTest
@testable import Component

final class ComponentSetTests: XCTestCase {

  func testContainsElementOfTypeFailsWhenNotPresent() throws {
    let set = ComponentSet()
    XCTAssertFalse(set.containsElement(ofType: ShoeComponent.self))
  }

  func testContainsElementOfTypeSucceedsWhenPresent() throws {
    var set = ComponentSet()
    let shoe = ShoeComponent()
    try set.insertElement(shoe)
    XCTAssertTrue(set.containsElement(ofType: ShoeComponent.self))
  }

  func testCanInsertElementSucceedsWhenNotPresent() throws {
    let set = ComponentSet()
    XCTAssertTrue(set.canInsertElement(ShoeComponent()))
  }

  func testCanInsertElementFailsWhenPresent() throws {
    var set = ComponentSet()
    try set.insertElement(ShoeComponent())
    XCTAssertFalse(set.canInsertElement(ShoeComponent()))
  }

  func testCanInsertElementOfDifferentTypeSucceeds() throws {
    var set = ComponentSet()
    try set.insertElement(ShoeComponent())
    XCTAssertTrue(set.canInsertElement(SockComponent()))
  }

  func testElementOfTypeReturnsInsertedInstance() throws {
    var set = ComponentSet()
    let shoe = ShoeComponent()
    try set.insertElement(shoe)
    XCTAssertIdentical(set.element(ofType: ShoeComponent.self), shoe)
  }

  func testElementOfTypeReturnsNilBeforeInserting() throws {
    let set = ComponentSet()
    XCTAssertNil(set.element(ofType: ShoeComponent.self))
  }

  func testInsertElementOfDuplicateTypeThrows() throws {
    var set = ComponentSet()
    let firstShoe = ShoeComponent()
    try set.insertElement(firstShoe)

    let secondShoe = ShoeComponent()
    XCTAssertThrowsError(try set.insertElement(secondShoe), "") { error in
      guard case .duplicateComponent = error as? ComponentSetError else {
        XCTFail()
        return
      }
    }
  }

  func testRemoveElementSucceedsAfterinserting() throws {
    var set = ComponentSet()
    let firstShoe = ShoeComponent()
    try set.insertElement(firstShoe)

    let retrieved = try set.removeElement(ofType: ShoeComponent.self)
    XCTAssertIdentical(retrieved, firstShoe)
  }

  func testRemoveelementFailsBeforeInserting() throws {
    var set = ComponentSet()

    XCTAssertThrowsError(try set.removeElement(ofType: ShoeComponent.self), "") { error in
      guard case let .componentOfTypeNotFound(name) = error as? ComponentSetError else {
        XCTFail()
        return
      }
      XCTAssertEqual(name, String(describing: ShoeComponent.self))
    }
  }
}

class ShoeComponent: Component {
}

class SockComponent: Component {
}

class ShirtComponent: Component {
}
