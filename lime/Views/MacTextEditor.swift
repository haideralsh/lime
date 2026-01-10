import SwiftUI
import AppKit

struct MacTextEditor: NSViewRepresentable {
    private enum Layout {
        static let fontSize: CGFloat = 24
        static let textContainerInset = NSSize(width: 40, height: 40)
    }
    
    @Binding var text: String
    
    private static let syntaxHighlighter = SyntaxHighlighter(
        font: NSFont.monospacedSystemFont(ofSize: Layout.fontSize, weight: .regular),
        defaultColor: SyntaxColors.defaultText
    )
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        configureTextContainer(textView)
        configureTextView(textView, coordinator: context.coordinator)
        configureScrollView(scrollView, with: textView)
        
        // Apply initial highlighting
        if let textStorage = textView.textStorage {
            Self.syntaxHighlighter.highlight(textStorage)
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            // Preserve selection
            let selectedRanges = textView.selectedRanges
            textView.string = text
            
            // Apply syntax highlighting after external text change
            if let textStorage = textView.textStorage {
                Self.syntaxHighlighter.highlight(textStorage)
            }
            
            // Restore selection if valid
            textView.selectedRanges = selectedRanges
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
        textView.backgroundColor = NSColor(red: 0x18/255.0, green: 0x19/255.0, blue: 0x17/255.0, alpha: 1.0)
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
        scrollView.backgroundColor = NSColor(red: 0x18/255.0, green: 0x19/255.0, blue: 0x17/255.0, alpha: 1.0)
        textView.frame = scrollView.contentView.bounds
    }
    
    final class Coordinator: NSObject, NSTextViewDelegate {
        private let parent: MacTextEditor
        
        init(_ parent: MacTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Apply syntax highlighting on every text change
            if let textStorage = textView.textStorage {
                MacTextEditor.syntaxHighlighter.highlight(textStorage)
            }
            
            parent.text = textView.string
        }
    }
}

#Preview {
    MacTextEditor(text: .constant("Hello, World!"))
        .frame(width: 400, height: 300)
}

