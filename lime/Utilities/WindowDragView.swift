import SwiftUI
import AppKit

struct WindowDragView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DraggableView()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    final class DraggableView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }
        
        override func mouseDown(with event: NSEvent) {
            if event.clickCount == 2 {
                window?.performZoom(nil)
            } else {
                super.mouseDown(with: event)
            }
        }
    }
}

