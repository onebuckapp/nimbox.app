// Nimbox - The missing GUI for Nimble, Nim's package manager.
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let newWindowSize = NSSize(width: 1200, height: 800) // Define the new size
    let windowFrame = NSRect(origin: self.frame.origin, size: newWindowSize) // Create a new frame with the desired size

    self.contentViewController = flutterViewController
    self.titlebarAppearsTransparent = true
    self.minSize = newWindowSize // Set the minimum size
    self.setFrame(windowFrame, display: true) // Set the new frame size explicitly

    self.styleMask.insert(.fullSizeContentView)
    self.titleVisibility = .hidden

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}