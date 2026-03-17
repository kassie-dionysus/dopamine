# App Source

`App/iOS` contains the shared SwiftUI entry point used by both the package executable target and the checked-in iOS Xcode project.

The app host stays intentionally thin. `DopamineUI` owns the prototype interface and `DopamineCore` owns the coaching behavior.
