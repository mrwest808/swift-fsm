import XCTest
@testable import FSM

struct TrafficMachine {
  enum State {
    case green
    case yellow
    case red
  }

  enum Event {
    case timer
  }

  let machine = StateMachine<State, Event>(initial: .green) { state, _ in
    switch state {
    case .green:
      return .yellow
    case .yellow:
      return .red
    case .red:
      return .green
    }
  }
}

struct SimpleMachine {
  enum State {
    case sitting
    case standing
  }

  enum Event {
    case sit
    case stand
  }

  let machine = StateMachine<State, Event>(initial: .standing) { state, event in
    switch (state, event) {
    case (.sitting, .stand):
      return .standing
    case (.standing, .sit):
      return .sitting
    default:
      return nil
    }
  }
}

struct AssociatedValuesMachine {
  enum State: Equatable {
    case idle
    case editing(Int)

    // For the sake of equality checking within the test suite
    static func ==(lhs: State, rhs: State) -> Bool {
      switch (lhs, rhs) {
      case (let .editing(lhsInt), let .editing(rhsInt)):
        return lhsInt == rhsInt
      case (.idle, .idle):
        return true
      default:
        return lhs == rhs
      }
    }
  }

  enum Event {
    case edit(Int)
    case save
  }

  let machine = StateMachine<State, Event>(initial: .idle) { state, event in
    switch (state, event) {
    case (.idle, let .edit(id)):
      return .editing(id)
    case (.editing(_), .save):
      return .idle
    default:
      return nil
    }
  }
}

final class FSMTests: XCTestCase {
  func testTrafficMachine() {
    let trafficMachine = TrafficMachine()
    let machine = trafficMachine.machine

    XCTAssertEqual(machine.currentState, TrafficMachine.State.green)
    machine.send(.timer)
    XCTAssertEqual(machine.currentState, TrafficMachine.State.yellow)
    machine.send(.timer)
    XCTAssertEqual(machine.currentState, TrafficMachine.State.red)
    machine.send(.timer)
    XCTAssertEqual(machine.currentState, TrafficMachine.State.green)
  }

  func testSimpleMachine() {
    let simpleMachine = SimpleMachine()
    let machine = simpleMachine.machine
    var lastEvent: SimpleMachine.Event?

    machine.on { event in
      lastEvent = event
    }

    XCTAssertEqual(lastEvent, nil)
    XCTAssertEqual(machine.currentState, SimpleMachine.State.standing)
    machine.send(.stand)
    XCTAssertEqual(lastEvent, nil)
    XCTAssertEqual(machine.currentState, SimpleMachine.State.standing)
    machine.send(.sit)
    XCTAssertEqual(lastEvent, SimpleMachine.Event.sit)
    XCTAssertEqual(machine.currentState, SimpleMachine.State.sitting)
    machine.send(.sit)
    XCTAssertEqual(machine.currentState, SimpleMachine.State.sitting)
    machine.send(.stand)
    XCTAssertEqual(lastEvent, SimpleMachine.Event.stand)
    XCTAssertEqual(machine.currentState, SimpleMachine.State.standing)
  }

  func testAssociatedValuesMachine() {
    let associatedValuesMachine = AssociatedValuesMachine()
    let machine = associatedValuesMachine.machine

    XCTAssertEqual(machine.currentState, AssociatedValuesMachine.State.idle)
    machine.send(.save)
    XCTAssertEqual(machine.currentState, AssociatedValuesMachine.State.idle)
    machine.send(.edit(1))
    XCTAssertEqual(machine.currentState, AssociatedValuesMachine.State.editing(1))
    machine.send(.edit(2))
    XCTAssertEqual(machine.currentState, AssociatedValuesMachine.State.editing(1))
    machine.send(.save)
    XCTAssertEqual(machine.currentState, AssociatedValuesMachine.State.idle)
  }

  static var allTests = [
    ("testTrafficMachine", testTrafficMachine),
    ("testSimpleMachine", testSimpleMachine),
    ("testAssociatedValuesMachine", testAssociatedValuesMachine),
  ]
}
