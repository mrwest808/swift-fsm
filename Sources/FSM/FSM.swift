//
//  FSM.swift
//  v0.1.2
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

  @Published var currentState: State
  @Published var previousState: State

  var eventPublisher = PassthroughSubject<Event, Never>()

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
