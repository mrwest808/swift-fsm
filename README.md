# FSM

Very simple finite state machine implementation.

## Installation

Install the `FSM` package [with Swift Package Manager](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app), using the following repository URL:

```
https://github.com/mrwest808/swift-fsm
```

## Usage

```swift
import FSM

enum State {
  case idle
  case editing(Int)
}

enum Event {
  case edit(Int)
  case save
}

// Declare the initial state and valid state transitions 
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

machine.onTransition { state, event in
  print("\(event): \(machine.previousState) -> \(state)")
}

machine.send(.edit(1))  // prints "edit(1): idle -> editing(1)"
machine.send(.save)     // prints "save: editing(1) -> idle"
machine.send(.save)     // prints nothing (invalid state transition)
```
