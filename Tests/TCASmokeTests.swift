import ComposableArchitecture
import XCTest

private struct CounterFeature: Reducer {
  struct State: Equatable {
    var count = 0
  }

  enum Action: Equatable {
    case increment
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .increment:
        state.count += 1
        return .none
      }
    }
  }
}

@MainActor
final class TCASmokeTests: XCTestCase {
  func testIncrement() async {
    let store = TestStore(initialState: CounterFeature.State()) {
      CounterFeature()
    }

    await store.send(.increment) {
      $0.count = 1
    }
  }
}
