import ComposableArchitecture
import Testing

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

struct TCASmokeTests {
  @MainActor
  @Test("CounterFeature increments count after increment action")
  func increment() async {
    let store = TestStore(initialState: CounterFeature.State()) {
      CounterFeature()
    }

    await store.send(.increment) {
      $0.count = 1
    }
  }
}
