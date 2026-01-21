import SwiftUI

struct ContentView: View {
    private enum Layout {
        static let editorMinWidth: CGFloat = 200
        static let sidebarMinWidth: CGFloat = 200
        static let sidebarMaxWidth: CGFloat = 600
    }
    
    @StateObject private var viewModel = DocumentViewModel()
    @State private var copiedMessage: String?
    
    var body: some View {
        HSplitView {
            MacTextEditor(text: $viewModel.text)
                .frame(minWidth: Layout.editorMinWidth)
            
            ResultsSidebar(lineResults: viewModel.lineResults, onCopy: {
                copiedMessage = "Copied result to clipboard"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    copiedMessage = nil
                }
            })
                .frame(minWidth: Layout.sidebarMinWidth)
                .frame(maxWidth: Layout.sidebarMaxWidth, maxHeight: .infinity)
                .overlay(
                    Rectangle()
                        .fill(LimeTheme.divider)
                        .frame(width: 1),
                    alignment: .leading
                )
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            StatusBar(sum: viewModel.sum, copiedMessage: copiedMessage, onTotalTap: {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = 10
                formatter.minimumFractionDigits = 0
                let formattedTotal = formatter.string(from: NSDecimalNumber(decimal: viewModel.sum)) ?? "\(viewModel.sum)"
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(formattedTotal, forType: .string)
                copiedMessage = "Copied to clipboard"
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    copiedMessage = nil
                }
            })
        }
        .background(LimeTheme.background)
        .background(WindowTabConfigurator())
    }
}

/// Configures the window to enable native tabbing
struct WindowTabConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.tabbingMode = .preferred
                window.tabbingIdentifier = "LimeMainWindow"
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

#Preview {
    ContentView()
}
