import UIKit

/// Keeps text entry inside Cortex on Apple's built-in iPhone keyboard.
///
/// Third-party keyboard extensions run code supplied by another app. Disabling
/// the keyboard extension point here prevents an unstable custom keyboard from
/// terminating the host app when a text field becomes first responder. Apple's
/// system keyboards, emoji keyboard, dictation and hardware keyboards remain
/// available.
final class CortexAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier
    ) -> Bool {
        extensionPointIdentifier != .keyboard
    }
}
