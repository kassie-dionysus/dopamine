import SwiftUI
import DopamineUI

@main
struct DopamineApp: App {
    var body: some Scene {
        WindowGroup("Dopamine") {
            RootContainerView()
        }
    }
}

private struct RootContainerView: View {
    var body: some View {
        #if os(macOS)
        DopamineRootView()
            .frame(minWidth: 960, minHeight: 640)
        #else
        DopamineRootView()
        #endif
    }
}
