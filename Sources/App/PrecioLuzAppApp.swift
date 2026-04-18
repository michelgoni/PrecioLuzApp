import SwiftUI
import ComposableArchitecture

@main
struct PrecioLuzAppApp: App {
  private let store = Store(initialState: AppFeature.State()) {
    AppFeature()
  }

  var body: some Scene {
    WindowGroup {
      AppShellView(store: store)
    }
  }
}
