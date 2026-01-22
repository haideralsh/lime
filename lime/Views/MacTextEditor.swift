import SwiftUI
import AppKit

struct MacTextEditor: NSViewRepresentable {
    private enum Layout {
        static let fontSize: CGFloat = 18
        static let lineHeight: CGFloat = 28
        static let textContainerInset = NSSize(width: 40, height: 40)
    }
    
    @Binding var text: String
    
    private var syntaxHighlighter: SyntaxHighlighter {
        SyntaxHighlighter(
            font: Typography.nsFont(size: Layout.fontSize),
            defaultColor: SyntaxColors.defaultText,
            lineHeight: Layout.lineHeight
        )
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        configureTextContainer(textView)
        configureTextView(textView, coordinator: context.coordinator)
        configureScrollView(scrollView, with: textView)
        
        if let textStorage = textView.textStorage {
            syntaxHighlighter.highlight(textStorage)
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        textView.backgroundColor = LimeTheme.backgroundNS
        scrollView.backgroundColor = LimeTheme.backgroundNS
        textView.textColor = .labelColor
        textView.insertionPointColor = .labelColor
        
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            
            if let textStorage = textView.textStorage {
                syntaxHighlighter.highlight(textStorage)
            }
            
            textView.selectedRanges = selectedRanges
        } else {
            if let textStorage = textView.textStorage {
                syntaxHighlighter.highlight(textStorage)
            }
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
        textView.font = Typography.nsFont(size: Layout.fontSize)
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = true
        textView.backgroundColor = LimeTheme.backgroundNS
        textView.textColor = .labelColor
        textView.insertionPointColor = .labelColor
        textView.autoresizingMask = [.width, .height]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.delegate = coordinator
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = Layout.lineHeight
        paragraphStyle.maximumLineHeight = Layout.lineHeight
        textView.defaultParagraphStyle = paragraphStyle
    }
    
    private func configureScrollView(_ scrollView: NSScrollView, with textView: NSTextView) {
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = LimeTheme.backgroundNS
        textView.frame = scrollView.contentView.bounds
    }
    
    final class Coordinator: NSObject, NSTextViewDelegate {
        private let parent: MacTextEditor
        
        init(_ parent: MacTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            let currentString = textView.string
            if currentString.contains("*") {
                let selectedRanges = textView.selectedRanges
                let newString = currentString.replacingOccurrences(of: "*", with: "×")
                textView.string = newString
                textView.selectedRanges = selectedRanges
            }
            
            if let textStorage = textView.textStorage {
                parent.syntaxHighlighter.highlight(textStorage)
            }
            
            parent.text = textView.string
        }
    }
}

#Preview {
    MacTextEditor(text: .constant("Hello, World!"))
        .frame(width: 400, height: 300)
}

