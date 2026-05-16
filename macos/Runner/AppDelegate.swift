// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import Cocoa
import FlutterMacOS
import UserNotifications
import WebKit

@main
class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate { // Conform to the protocol
  override func applicationDidFinishLaunching(_ notification: Notification) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        print("Notification permission error: \(error)")
      }
    }
    UNUserNotificationCenter.current().delegate = self // Now valid

    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    // Register platform view factory
    let registrar = controller.registrar(forPlugin: "MacOSWebViewPlugin")
    let factory = MacOSWebViewFactory(messenger: registrar.messenger)
    registrar.register(factory, withId: "macos_webview")
    RegisterGeneratedPlugins(registry: controller)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // Optional: Handle foreground notifications
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .sound]) // Show notifications while the app is in the foreground
  }

  // Optional: Handle notification interactions
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    print("Notification clicked: \(response.notification.request.content.userInfo)")
    completionHandler()
  }
}