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
  enum State {
    case idle
    case editing(Int)
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

// Needed for equality assertions in tests below
extension AssociatedValuesMachine.State: Equatable {
  static func ==(lhs: AssociatedValuesMachine.State, rhs: AssociatedValuesMachine.State) -> Bool {
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

@available(OSX 10.15, *)
struct ObservableCountMachine {
  enum State {
    case count(Int)
  }

  enum Event {
    case increment
    case decrement
    case add(Int)
  }

  let machine = ObservableStateMachine<State, Event>(initial: .count(0)) { state, event in
    switch (state, event) {
    case (let .count(n), .increment):
      return .count(n + 1)
    case (let .count(n), .decrement):
      return .count(n - 1)
    case (let .count(n), let .add(amount)):
      return .count(n + amount)
    }
  }
}

// Needed for equality assertions in tests below

@available(OSX 10.15, *)
extension ObservableCountMachine.State: Equatable {
  static func ==(lhs: ObservableCountMachine.State, rhs: ObservableCountMachine.State) -> Bool {
    switch (lhs, rhs) {
    case (let .count(lhsInt), let .count(rhsInt)):
      return lhsInt == rhsInt
    }
  }
}

@available(OSX 10.15, *)
extension ObservableCountMachine.Event: Equatable {
  static func ==(lhs: ObservableCountMachine.Event, rhs: ObservableCountMachine.Event) -> Bool {
    switch (lhs, rhs) {
    case (let .add(lhsInt), let .add(rhsInt)):
      return lhsInt == rhsInt
    case (.increment, .increment), (.decrement, .decrement):
      return true
    default:
      return false
    }
  }
}

final class FSMTests: XCTestCase {
  func testTrafficMachine() {
    typealias S = TrafficMachine.State

    let trafficMachine = TrafficMachine()
    let machine = trafficMachine.machine

    XCTAssertEqual(machine.currentState, S.green)
    machine.send(.timer)
    XCTAssertEqual(machine.currentState, S.yellow)
    machine.send(.timer)
    XCTAssertEqual(machine.currentState, S.red)
    machine.send(.timer)
    XCTAssertEqual(machine.currentState, S.green)
  }

  func testSimpleMachine() {
    typealias S = SimpleMachine.State
    typealias E = SimpleMachine.Event

    let simpleMachine = SimpleMachine()
    let machine = simpleMachine.machine
    var lastTransitionEvent: E?
    var lastEvent: E?
    var onStateTransitionCallCount = 0
    var onEventCallCount = 0

    machine.onTransition { _, event in
      lastTransitionEvent = event
      onStateTransitionCallCount += 1
    }

    machine.onEvent { event, _ in
      lastEvent = event
      onEventCallCount += 1
    }

    XCTAssertEqual(lastEvent, nil)
    XCTAssertEqual(lastTransitionEvent, nil)
    XCTAssertEqual(onEventCallCount, 0)
    XCTAssertEqual(onStateTransitionCallCount, 0)
    XCTAssertEqual(machine.currentState, S.standing)
    machine.send(.stand)
    XCTAssertEqual(lastEvent, E.stand)
    XCTAssertEqual(lastTransitionEvent, nil)
    XCTAssertEqual(machine.currentState, S.standing)
    machine.send(.sit)
    XCTAssertEqual(lastEvent, E.sit)
    XCTAssertEqual(machine.currentState, S.sitting)
    machine.send(.sit)
    XCTAssertEqual(machine.currentState, S.sitting)
    machine.send(.stand)
    XCTAssertEqual(lastTransitionEvent, E.stand)
    XCTAssertEqual(onEventCallCount, 4)
    XCTAssertEqual(onStateTransitionCallCount, 2)
    XCTAssertEqual(machine.currentState, S.standing)
  }

  func testAssociatedValuesMachine() {
    typealias S = AssociatedValuesMachine.State

    let associatedValuesMachine = AssociatedValuesMachine()
    let machine = associatedValuesMachine.machine

    XCTAssertEqual(machine.currentState, S.idle)
    machine.send(.save)
    XCTAssertEqual(machine.currentState, S.idle)
    machine.send(.edit(1))
    XCTAssertEqual(machine.currentState, S.editing(1))
    machine.send(.edit(2))
    XCTAssertEqual(machine.currentState, S.editing(1))
    machine.send(.save)
    XCTAssertEqual(machine.currentState, S.idle)
  }

  @available(OSX 10.15, *)
  func testObservableCountMachine() {
    typealias S = ObservableCountMachine.State
    typealias E = ObservableCountMachine.Event

    let observableCountMachine = ObservableCountMachine()
    let machine = observableCountMachine.machine
    var observedCurrentState = machine.currentState
    var observedPreviousState = machine.previousState
    var observedEvents = [E]()

    let disposables = [
      machine.$currentState.sink { state in
        observedCurrentState = state
      },
      machine.$previousState.sink { state in
        observedPreviousState = state
      },
      machine.eventPublisher.sink { event in
        observedEvents.append(event)
      }
    ]

    XCTAssertEqual(observedCurrentState, S.count(0))
    XCTAssertEqual(observedPreviousState, S.count(0))
    XCTAssertEqual(observedEvents, [])
    XCTAssertEqual(machine.currentState, S.count(0))
    machine.send(.increment)
    XCTAssertEqual(machine.currentState, S.count(1))
    machine.send(.increment)
    XCTAssertEqual(machine.currentState, S.count(2))
    machine.send(.decrement)
    XCTAssertEqual(machine.currentState, S.count(1))
    machine.send(.add(10))
    XCTAssertEqual(machine.currentState, S.count(11))
    XCTAssertEqual(observedCurrentState, S.count(11))
    XCTAssertEqual(observedPreviousState, S.count(1))
    XCTAssertEqual(observedEvents, [.increment, .increment, .decrement, .add(10)])

    for disposable in disposables {
      disposable.cancel()
    }
  }

  static var allTests = [
    ("testTrafficMachine", testTrafficMachine),
    ("testSimpleMachine", testSimpleMachine),
    ("testAssociatedValuesMachine", testAssociatedValuesMachine),
  ]
}
