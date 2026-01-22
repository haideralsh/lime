import SwiftUI
import AppKit

struct ResultsSidebar: View {
    fileprivate enum Layout {
        static let fontSize: CGFloat = 18
        static let lineHeight: CGFloat = 28
        static let topPadding: CGFloat = 40
        static let horizontalPadding: CGFloat = 16
    }
    
    let lineResults: [LineResult]
    var onCopy: (() -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(Array(lineResults.enumerated()), id: \.offset) { index, result in
                        ResultRow(displayString: result.displayString, onCopy: onCopy)
                            .frame(height: Layout.lineHeight)
                    }
                }
                .padding(.top, Layout.topPadding)
                .padding(.horizontal, Layout.horizontalPadding)
                .frame(minWidth: geometry.size.width, alignment: .trailing)
            }
        }
        .background(LimeTheme.background)
    }
}

private struct ResultRow: View {
    let displayString: String?
    var onCopy: (() -> Void)?
    
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            Spacer()
            
            if let displayString {
                Text(displayString)
                    .font(Typography.font(size: ResultsSidebar.Layout.fontSize))
                    .foregroundColor(LimeTheme.sidebarText)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        isHovering = hovering
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .onTapGesture {
                        copyToPasteboard(displayString)
                        onCopy?()
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    private var backgroundColor: Color {
        isHovering && displayString != nil ? LimeTheme.rowHover : .clear
    }
    
    private func copyToPasteboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}

#Preview {
    ResultsSidebar(lineResults: [
        LineResult(lineIndex: 0, sourceRange: NSRange(), value: .quantity(.scalar(42)), error: nil),
        LineResult(lineIndex: 1, sourceRange: NSRange(), value: nil, error: nil),
        LineResult(lineIndex: 2, sourceRange: NSRange(), value: .quantity(.scalar(123.456)), error: nil),
    ])
    .frame(width: 200, height: 300)
}
