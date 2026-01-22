import SwiftUI
import AppKit

@main
struct LimeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        Typography.registerFonts()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            // Add standard New Tab command
            CommandGroup(after: .newItem) {
                Button("New Tab") {
                    appDelegate.openNewTabbedWindow()
                }
                .keyboardShortcut("t", modifiers: .command)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var windowControllers: [NSWindowController] = []
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = true
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = true
    }
    
    func openNewTabbedWindow() {
        guard let currentWindow = NSApp.keyWindow else { return }
        
        let newWindow = NSWindow(
            contentRect: currentWindow.frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = "Lime"
        newWindow.tabbingMode = .preferred
        newWindow.tabbingIdentifier = "LimeMainWindow"
        newWindow.delegate = self
        
        newWindow.contentView = NSHostingView(rootView: ContentView())
        
        let controller = NSWindowController(window: newWindow)
        windowControllers.append(controller)
        
        currentWindow.addTabbedWindow(newWindow, ordered: .above)
        controller.showWindow(nil)
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow else { return }
        
        // Drop our strong reference when AppKit is tearing down the tab/window.
        windowControllers.removeAll { $0.window === closingWindow }
    }
    
    @objc func newWindowForTab(_ sender: Any?) {
        openNewTabbedWindow()
    }
}
