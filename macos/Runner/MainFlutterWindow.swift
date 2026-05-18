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