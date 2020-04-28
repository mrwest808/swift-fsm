//
//  FSM.swift
//
//
//  Created by Johan West on 2020-04-28.
//

public final class StateMachine<State, Event> {
  public typealias StateEventMapper = (State, Event) -> State?
  public typealias OnTransitionClosure = (Event) -> Void

  private var stateEventMapper: StateEventMapper
  private var onTransitionClosure: OnTransitionClosure?

  public var currentState: State
  public var previousState: State

  init(initial: State, _ stateEventMapper: @escaping StateEventMapper) {
    self.stateEventMapper = stateEventMapper
    currentState = initial
    previousState = initial
  }

  public func send(_ event: Event) {
    if let nextState = stateEventMapper(currentState, event) {
      previousState = currentState
      currentState = nextState

      if let onTransitionClosure = self.onTransitionClosure {
        onTransitionClosure(event)
      }
    }
  }

  public func on(_ onTransitionClosure: @escaping OnTransitionClosure) {
    self.onTransitionClosure = onTransitionClosure
  }
}
