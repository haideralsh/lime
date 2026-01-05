import SwiftUI

struct ContentView: View {
    private enum Layout {
        static let editorMinWidth: CGFloat = 200
        static let sidebarMinWidth: CGFloat = 200
        static let sidebarMaxWidth: CGFloat = 600
    }
    
    @StateObject private var viewModel = DocumentViewModel()
    
    var body: some View {
        HSplitView {
            MacTextEditor(text: $viewModel.text)
                .frame(minWidth: Layout.editorMinWidth)
            
            ResultsSidebar(lineResults: viewModel.lineResults)
                .frame(minWidth: Layout.sidebarMinWidth)
                .frame(maxWidth: Layout.sidebarMaxWidth, maxHeight: .infinity)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 1),
                    alignment: .leading
                )
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            StatusBar(lineResults: viewModel.lineResults)
        }
        .background(Color.black)
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
