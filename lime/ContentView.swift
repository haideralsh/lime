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

struct StatusBar: View {
    private enum Layout {
        static let height: CGFloat = 24
        static let horizontalPadding: CGFloat = 12
        static let fontSize: CGFloat = 12
        static let backgroundOpacity: CGFloat = 0.8
    }
    
    let characterCount: Int
    
    var body: some View {
        HStack {
            Spacer()
            Text("\(characterCount) characters")
                .font(.system(size: Layout.fontSize, weight: .regular, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .frame(height: Layout.height)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(Layout.backgroundOpacity))
    }
}

struct ContentView: View {
    private enum Layout {
        static let titleBarHeight: CGFloat = 28
        static let editorMinWidth: CGFloat = 200
        static let sidebarMinWidth: CGFloat = 50
        static let dividerColor = NSColor(white: 0.2, alpha: 1.0)
    }
    
    @State private var text = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: Layout.titleBarHeight)
                
                CustomHSplitView(
                    dividerColor: Layout.dividerColor,
                    left: {
                        MacTextEditor(text: $text)
                            .frame(minWidth: Layout.editorMinWidth)
                    },
                    right: {
                        Color.black
                            .frame(minWidth: Layout.sidebarMinWidth, maxWidth: .infinity, maxHeight: .infinity)
                    }
                )
                
                StatusBar(characterCount: text.count)
            }
            
            CustomTitleBar(title: "Placeholder title")
        }
        .ignoresSafeArea(edges: .top)
        .background(WindowAccessor())
    }
}

struct CustomHSplitView<Left: View, Right: View>: NSViewRepresentable {
    let dividerColor: NSColor
    let left: Left
    let right: Right
    
    init(dividerColor: NSColor, @ViewBuilder left: () -> Left, @ViewBuilder right: () -> Right) {
        self.dividerColor = dividerColor
        self.left = left()
        self.right = right()
    }
    
    func makeNSView(context: Context) -> NSSplitView {
        let splitView = StyledSplitView(dividerColor: dividerColor)
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        
        let leftView = NSHostingView(rootView: left)
        let rightView = NSHostingView(rootView: right)
        
        splitView.addArrangedSubview(leftView)
        splitView.addArrangedSubview(rightView)
        
        return splitView
    }
    
    func updateNSView(_ nsView: NSSplitView, context: Context) {
        if let leftView = nsView.arrangedSubviews[0] as? NSHostingView<Left> {
            leftView.rootView = left
        }
        if let rightView = nsView.arrangedSubviews[1] as? NSHostingView<Right> {
            rightView.rootView = right
        }
    }
    
    private class StyledSplitView: NSSplitView {
        let customDividerColor: NSColor
        
        init(dividerColor: NSColor) {
            self.customDividerColor = dividerColor
            super.init(frame: .zero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var dividerColor: NSColor {
            customDividerColor
        }
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
