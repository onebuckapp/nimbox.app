// Nimbox - The missing GUI for Nimble, Nim's package manager.
//
//      Copyright (c) 2026 George Lemon
//      Released under the GPLv3 License
//      https://onebuck.app | https://github.com/onebuckapp

import FlutterMacOS
import WebKit
import Cocoa

class AssetSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let url = urlSchemeTask.request.url!
        // Example: myapp://assets/app.js
        if url.host == "assets" {
            let assetName = url.host! + url.path
            if let assetPath = Bundle.main.path(forResource: String(assetName), ofType: nil) {
                if let data = try? Data(contentsOf: URL(fileURLWithPath: assetPath)) {
                    let mimeType = mimeTypeForPath(assetPath)
                    let response = URLResponse(url: url, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: nil)
                    urlSchemeTask.didReceive(response)
                    urlSchemeTask.didReceive(data)
                    urlSchemeTask.didFinish()
                    return
                }
            }
        }
        urlSchemeTask.didFailWithError(NSError(domain: "AssetNotFound", code: 404))
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private func mimeTypeForPath(_ path: String) -> String {
        if path.hasSuffix(".js") { return "application/javascript" }
        if path.hasSuffix(".css") { return "text/css" }
        if path.hasSuffix(".html") { return "text/html" }
        return "application/octet-stream"
    }
}

class CustomWKWebView: WKWebView, WKScriptMessageHandler {
    let messenger: FlutterBinaryMessenger
    let channel: FlutterMethodChannel
    var lastMenuAction: String?
    var lastRightClickEvent: NSEvent?
    var lastElementInfo: [String: Any]? = nil

    init(frame: CGRect, configuration: WKWebViewConfiguration, messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        self.channel = FlutterMethodChannel(name: "custom_webview_context_menu", binaryMessenger: messenger)
        super.init(frame: frame, configuration: configuration)
        
        // ensures background is transparent
        self.setValue(false, forKey: "drawsBackground")
        // self.setupJSBridge()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        // Remove the "Services" menu item if it exists
        super.willOpenMenu(menu, with: event)
        if let info = lastElementInfo {
            // if a link has custom attribute `data-action-type="file"` 
            if info["type"] as? String == "link", /*let href = info["href"] as? String,*/ let actionType = info["actionType"] as? String {
                menu.items.removeAll()
                if actionType == "file" {
                    let openFile = NSMenuItem(title: "Open with", action: #selector(openLinkInNewTab(_:)), keyEquivalent: "")
                    openFile.target = self
                    menu.addItem(openFile)

                    let reveal = NSMenuItem(title: "Reveal in Finder", action: #selector(openLinkInNewTab(_:)), keyEquivalent: "r")
                    reveal.target = self
                    reveal.keyEquivalentModifierMask = [.command, .option]
                    menu.addItem(reveal)

                    let sep = NSMenuItem.separator()
                    menu.addItem(sep)

                    let copilot = NSMenuItem(title: "Copilot", action: #selector(openLinkInNewTab(_:)), keyEquivalent: "")
                    copilot.target = self
                    // copilot.keyEquivalentModifierMask = [.command, .option]
                    menu.addItem(copilot)

                    let sep2 = NSMenuItem.separator()
                    menu.addItem(sep2)

                    // rename file with key equivalent enter
                    let renameFile = NSMenuItem(title: "Rename...", action: #selector(openLinkInNewTab(_:)), keyEquivalent: "\r")
                    renameFile.target = self
                    menu.addItem(renameFile)
                
                    let deleteFile = NSMenuItem(title: "Delete", action: #selector(openLinkInNewTab(_:)), keyEquivalent: "\u{8}")
                    deleteFile.target = self
                    deleteFile.keyEquivalentModifierMask = [.command]
                    menu.addItem(deleteFile)

                } else {
                    let openLink = NSMenuItem(title: "Open Link", action: #selector(openLinkInNewTab(_:)), keyEquivalent: "")
                    openLink.target = self
                    menu.addItem(openLink)
                }
            } else if info["type"] as? String == "image", let src = info["src"] as? String {
                let saveImage = NSMenuItem(title: "Save Image (\(src))", action: #selector(saveImage(_:)), keyEquivalent: "")
                saveImage.target = self
                menu.addItem(saveImage)
            } else {
                // Add default item or other actions based on the type
                let defaultItem = NSMenuItem(title: "Default Action", action: nil, keyEquivalent: "")
                menu.addItem(defaultItem)
            }
        } else {
            let defaultItem = NSMenuItem(title: "Default Action", action: nil, keyEquivalent: "")
            menu.addItem(defaultItem)
        }
    }

    @objc func openLinkInNewTab(_ sender: Any?) {
        // Implement your logic here
        print("Open link in new tab")
    }

    @objc func saveImage(_ sender: Any?) {
        // Implement your logic here
        print("Save image as...")
    }

    // override func viewDidMoveToWindow() {
    //     super.viewDidMoveToWindow()
    //     if let window = self.window {
    //         window.makeFirstResponder(self)
    //     }
    // }

    override func selectAll(_ sender: Any?) {
        // Forward the select all command to the web content
        self.evaluateJavaScript("document.execCommand('selectAll')", completionHandler: nil)
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }
    
    func buildMenu(from items: [[String: Any]]) -> NSMenu {
        let menu = NSMenu()
        for item in items {
            let title = item["title"] as? String ?? ""
            if let children = item["children"] as? [[String: Any]] {
                // Create submenu
                let submenuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                submenuItem.submenu = buildMenu(from: children)
                menu.addItem(submenuItem)
            } else {
                let actionId = item["actionId"] as? String ?? ""
                let menuItem = NSMenuItem(title: title, action: #selector(self.menuAction(_:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.representedObject = actionId
                menu.addItem(menuItem)
            }
        }
        return menu
    }

    // override func rightMouseDown(with event: NSEvent) {
    //     self.lastRightClickEvent = event // Store the event for later use
    //     channel.invokeMethod("getContextMenuItems", arguments: nil) { result in
    //         guard let items = result as? [[String: Any]] else { return }
    //         let menu = self.buildMenu(from: items)
    //         NSMenu.popUpContextMenu(menu, with: event, for: self)
    //     }
    // }

    override func mouseDown(with event: NSEvent) {
        // self.window?.makeFirstResponder(self)
        super.mouseDown(with: event)
        channel.invokeMethod("unfocusTextFields", arguments: nil)
    }

    @objc func menuAction(_ sender: NSMenuItem) {
        print("Menu action triggered: \(sender.title)")
        if let actionId = sender.representedObject as? String {
            if actionId == "inspect" {
                // if let event = self.lastRightClickEvent {
                    // let pointInWindow = event.locationInWindow
                    // let pointInView = self.convert(pointInWindow, from: nil)
                    // print("Inspecting element at point: \(pointInView)")
                    // Always use Objective-C runtime to call inspectElementAt:
                    
                    let selector = NSSelectorFromString("inspectElementAt:")
                    if self.responds(to: selector) {
                        let pointValue = NSValue(point: CGPoint(x: 0, y: 0))
                        self.perform(selector, with: pointValue)
                    }
                    // Bring the inspector window to the front after a short delay
                    // DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    //     for window in NSApp.windows {
                    //         if window.title.contains("Web Inspector") {
                    //             print("Bringing Web Inspector window to front")
                    //             window.makeKeyAndOrderFront(nil)
                    //         }
                    //     }
                    // }
                // }
            } else {
                // Call Dart with the selected actionId
                channel.invokeMethod("onMenuItemSelected", arguments: ["actionId": actionId])
            }
        }
    }



    // JS Bridge Methods
    private func setupJSBridge() {
        self.configuration.userContentController.add(self, name: "elementInfo")
        let js = """
        document.addEventListener('contextmenu', function(e) {
            let info = {};
            if (e.target.tagName === 'A') {
                info.type = 'link';
                info.href = e.target.href;
                if (e.target.hasAttribute('data-action-type')) {
                    info.actionType = e.target.getAttribute('data-action-type');
                }
            } else if (e.target.tagName === 'IMG') {
                info.type = 'image';
                info.src = e.target.src;
            } else {
                info.type = 'other';
            }
            window.webkit.messageHandlers.elementInfo.postMessage(info);
        }, true);
        """
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        self.configuration.userContentController.addUserScript(script)
    }

    // Receive JS messages
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "elementInfo", let info = message.body as? [String: Any] {
            self.lastElementInfo = info
        }
    }    
}

public class MacOSWebViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }


    public func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
        
        print("MacOSWebViewFactory initialized with messenger: \(messenger)")
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        // config.setURLSchemeHandler(AssetSchemeHandler(), forURLScheme: "app")

        let webView = CustomWKWebView(frame: .zero, configuration: config, messenger: messenger)
        webView.translatesAutoresizingMaskIntoConstraints = true

        // Handle initialization parameters
        if let args = args as? [String: Any] {
            if let urlString = args["url"] as? String,
                      let url = URL(string: urlString) {
                // Fallback to loading URL if html is not provided
                webView.load(URLRequest(url: url))
            } else if let html = args["html"] as? String {
                // Load HTML string
                webView.loadHTMLString(html, baseURL: nil)
            }
        }
        return webView
    }
    
    public func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
