/*
    Nimbox - The missing GUI for Nimble, Nim's package manager.

    Copyright (C) 2026  George Lemon from OpenPeeps

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import Cocoa
import FlutterMacOS
import UserNotifications
import WebKit

@main
class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  var statusItem: NSStatusItem?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        print("Notification permission error: \(error)")
      }
    }
    UNUserNotificationCenter.current().delegate = self // Now valid

    // Register the webview plugin
    let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
    let registrar = controller.registrar(forPlugin: "MacOSWebViewPlugin")
    let factory = MacOSWebViewFactory(messenger: registrar.messenger)
    registrar.register(factory, withId: "macos_webview")
    RegisterGeneratedPlugins(registry: controller)
    
    setupTrayMenu()
    super.applicationDidFinishLaunching(notification)
  }

  func setupTrayMenu() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    if let button = statusItem?.button {
      if #available(macOS 11.0, *) {
        button.image = NSImage(systemSymbolName: "shippingbox.fill", accessibilityDescription: "Nimbox")
      } else {
        button.image = NSImage(named: NSImage.applicationIconName)
        button.title = "NB"
      }
    }

    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "Open Nimbox", action: #selector(showWindow), keyEquivalent: "o"))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

    statusItem?.menu = menu
  }

  @objc func showWindow() {
    NSApp.activate(ignoringOtherApps: true)
    mainFlutterWindow?.makeKeyAndOrderFront(nil)
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