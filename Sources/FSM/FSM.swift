//
//  FSM.swift
//
//
//  Created by Johan West on 2020-04-28.
//

import Combine

public final class StateMachine<State, Event> {
  public typealias StateEventMapper = (State, Event) -> State?
  public typealias OnStateTransitionClosure = (State, Event) -> Void
  public typealias OnEventClosure = (Event, State) -> Void

  private var stateEventMapper: StateEventMapper
  private var onStateTransitionClosure: OnStateTransitionClosure?
  private var onEventClosure: OnEventClosure?

  public var currentState: State
  public var previousState: State

  public init(initial: State, _ stateEventMapper: @escaping StateEventMapper) {
    self.stateEventMapper = stateEventMapper
    currentState = initial
    previousState = initial
  }

  public func send(_ event: Event) {
    if let nextState = stateEventMapper(currentState, event) {
      previousState = currentState
      currentState = nextState

      if let onStateTransitionClosure = self.onStateTransitionClosure {
        onStateTransitionClosure(currentState, event)
      }
    }

    if let onEventClosure = self.onEventClosure {
      onEventClosure(event, currentState)
    }
  }

  public func onTransition(_ onStateTransitionClosure: @escaping OnStateTransitionClosure) {
    self.onStateTransitionClosure = onStateTransitionClosure
  }

  public func onEvent(_ onEventClosure: @escaping OnEventClosure) {
    self.onEventClosure = onEventClosure
  }
}

@available(OSX 10.15, *)
public final class ObservableStateMachine<State, Event>: ObservableObject {
  public typealias StateEventMapper = (State, Event) -> State?

  private var stateEventMapper: StateEventMapper

  @Published public var currentState: State
  @Published public var previousState: State

  public var eventPublisher = PassthroughSubject<Event, Never>()

  public init(initial: State, _ stateEventMapper: @escaping StateEventMapper) {
    self.stateEventMapper = stateEventMapper
    currentState = initial
    previousState = initial
  }

  public func send(_ event: Event) {
    if let nextState = stateEventMapper(currentState, event) {
      previousState = currentState
      currentState = nextState
    }

    eventPublisher.send(event)
  }
}

@available(OSX 10.15, *)
open class Unstable_ObservableEventPublisher<Event>: ObservableObject {
  public typealias Unsubscriber = () -> Void

  public static func subscribe(to disposables: [AnyCancellable]) -> Unsubscriber {
    return {
      for disposable in disposables {
        disposable.cancel()
      }
    }
  }

  public final var eventPublisher = PassthroughSubject<Event, Never>()

  public func send(_ event: Event) {
    receive(event: event)
    eventPublisher.send(event)
  }

  func receive(event: Event) {}
}

@available(OSX 10.15, *)
open class Unstable_ObservableStateMachine<State, Event>: Unstable_ObservableEventPublisher<Event> {
  public typealias StateEventMapper = (State, Event) -> State?

  private var stateEventMapper: StateEventMapper

  @Published public final var currentState: State
  @Published public final var previousState: State

  public init(initial: State, _ stateEventMapper: @escaping StateEventMapper) {
    self.stateEventMapper = stateEventMapper
    currentState = initial
    previousState = initial
  }

  public override func send(_ event: Event) {
    if let nextState = stateEventMapper(currentState, event) {
      previousState = currentState
      currentState = nextState
      receive(transitionBy: event, to: currentState, from: previousState)
    }

    super.send(event)
  }

  func receive(transitionBy event: Event, to: State, from: State) {}
}

// =============================================================================
// EXPERIMENTAL NEW API
// TODO: Add tests
// =============================================================================
//
//public class ObservableEventPublisher<Event>: ObservableObject {
//  typealias Unsubscriber = () -> Void
//
//  static func subscribe(to disposables: [AnyCancellable]) -> Unsubscriber {
//    return {
//      for disposable in disposables {
//        disposable.cancel()
//      }
//    }
//  }
//
//  public final var eventPublisher = PassthroughSubject<Event, Never>()
//
//  public func send(_ event: Event) {
//    receive(event: event)
//    eventPublisher.send(event)
//  }
//
//  func receive(event: Event) {}
//}
//
//public class ObservableStateMachine<State, Event>: ObservableEventPublisher<Event> {
//  public typealias StateEventMapper = (State, Event) -> State?
//
//  private var stateEventMapper: StateEventMapper
//
//  @Published public final var currentState: State
//  @Published public final var previousState: State
//
//  public init(initial: State, _ stateEventMapper: @escaping StateEventMapper) {
//    self.stateEventMapper = stateEventMapper
//    currentState = initial
//    previousState = initial
//  }
//
//  public override func send(_ event: Event) {
//    if let nextState = stateEventMapper(currentState, event) {
//      previousState = currentState
//      currentState = nextState
//      receive(transitionBy: event, to: currentState, from: previousState)
//    }
//
//    super.send(event)
//  }
//
//  func receive(transitionBy event: Event, to: State, from: State) {}
//}
//
// =============================================================================
// USAGE EXAMPLES:
// =============================================================================
//
//final class CounterState: ObservableEventPublisher<CounterState.Event> {
//  enum Event {
//    case increment
//  }
//
//  @Published var count = 0
//
//  override func receive(event: Event) {
//    switch event {
//    case .increment:
//      count += 1
//    }
//  }
//}
//
//let counter = CounterState()
//var unsubscribe: CounterState.Unsubscriber
//
//unsubscribe = CounterState.subscribe(to: [
//  counter.eventPublisher.sink { event in
//    print("Event: \(event), Count: \(counter.count)")
//  }
//])
//
//print("Count: \(counter.count)")
//counter.send(.increment)
//print("Count: \(counter.count)")
//
//unsubscribe()
//
//final class TrafficLightMachine: ObservableStateMachine<TrafficLightMachine.State, TrafficLightMachine.Event> {
//  enum State {
//    case green
//    case yellow
//    case red
//  }
//
//  enum Event {
//    case timer
//  }
//
//  @Published var rounds = 0
//  var yellowCount = 0
//
//  init() {
//    super.init(initial: .green) { state, _ in
//      switch (state) {
//      case .green:
//        return .yellow
//      case .yellow:
//        return .red
//      case .red:
//        return .green
//      }
//    }
//  }
//
//  override func receive(transitionBy event: Event, to: State, from: State) {
//    if to == .green {
//      rounds += 1
//    }
//
//    if to == .yellow {
//      yellowCount += 1
//    }
//  }
//}
//
//let trafficLight = TrafficLightMachine()
//
//print("\n===\n")
//
//print("Yellow count: \(trafficLight.yellowCount)")
//
//for iteration in 1...10 {
//  if iteration == 1 {
//    print("Light: \(trafficLight.currentState) (rounds: \(trafficLight.rounds))")
//  }
//
//  trafficLight.send(.timer)
//  print("Light: \(trafficLight.currentState) (rounds: \(trafficLight.rounds))")
//}
//
//print("Yellow count: \(trafficLight.yellowCount)")
//
//final class HumanMachine: ObservableStateMachine<HumanMachine.State, HumanMachine.Event> {
//  enum State {
//    case standing
//    case sitting
//  }
//
//  enum Event {
//    case sit
//    case stand
//  }
//
//  init() {
//    super.init(initial: .standing) { state, event in
//      switch (state, event) {
//      case (.standing, .sit):
//        return .sitting
//      case (.sitting, .stand):
//        return .standing
//      default:
//        return nil
//      }
//    }
//  }
//}
//
//let human = HumanMachine()
//
//print("\n===\n")
//
//print("State: \(human.currentState)")
//human.send(.stand)
//print("State: \(human.currentState)")
//human.send(.sit)
//print("State: \(human.currentState)")
//human.send(.stand)
//print("State: \(human.currentState)")
