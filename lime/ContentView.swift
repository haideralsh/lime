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

struct CustomTitleBar: View {
    private enum Layout {
        static let height: CGFloat = 28
        static let trafficLightWidth: CGFloat = 80
        static let fontSize: CGFloat = 13
        static let backgroundOpacity: CGFloat = 0.8
    }
    
    let title: String
    
    var body: some View {
        ZStack {
            WindowDragView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: Layout.trafficLightWidth)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: Layout.fontSize))
                    .foregroundColor(.secondary)
                    .allowsHitTesting(false)
                
                Spacer()
                
                Color.clear
                    .frame(width: Layout.trafficLightWidth)
            }
        }
        .frame(height: Layout.height)
        .background(Color.black.opacity(Layout.backgroundOpacity))
    }
}

struct MacTextEditor: NSViewRepresentable {
    private enum Layout {
        static let fontSize: CGFloat = 18
        static let textContainerInset = NSSize(width: 40, height: 40)
    }
    
    @Binding var text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        configureTextContainer(textView)
        configureTextView(textView, coordinator: context.coordinator)
        configureScrollView(scrollView, with: textView)
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func configureTextContainer(_ textView: NSTextView) {
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        textView.minSize = .zero
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
    }
    
    private func configureTextView(_ textView: NSTextView, coordinator: Coordinator) {
        textView.textContainerInset = Layout.textContainerInset
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: Layout.fontSize, weight: .regular)
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = .black
        textView.textColor = .textColor
        textView.insertionPointColor = .textColor
        textView.autoresizingMask = [.width, .height]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.delegate = coordinator
    }
    
    private func configureScrollView(_ scrollView: NSScrollView, with textView: NSTextView) {
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(white: 1.0, alpha: 0.3)
        textView.frame = scrollView.contentView.bounds
    }
    
    final class Coordinator: NSObject, NSTextViewDelegate {
        private let parent: MacTextEditor
        
        init(_ parent: MacTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

struct ContentView: View {
    private enum Layout {
        static let titleBarHeight: CGFloat = 28
        static let editorMinWidth: CGFloat = 200
        static let sidebarMinWidth: CGFloat = 50
    }
    
    @State private var text = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: Layout.titleBarHeight)
                
                HSplitView {
                    MacTextEditor(text: $text)
                        .frame(minWidth: Layout.editorMinWidth)
                    
                    Color.black
                        .frame(minWidth: Layout.sidebarMinWidth, maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            CustomTitleBar(title: "Placeholder title")
        }
        .ignoresSafeArea(edges: .top)
        .background(WindowAccessor())
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

#Preview {
    ContentView()
}
