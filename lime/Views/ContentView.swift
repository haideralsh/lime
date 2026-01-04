import SwiftUI

struct ContentView: View {
    private enum Layout {
        static let titleBarHeight: CGFloat = 28
        static let editorMinWidth: CGFloat = 200
        static let sidebarMinWidth: CGFloat = 200
        static let sidebarMaxWidth: CGFloat = 600
    }
    
    @StateObject private var viewModel = DocumentViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: Layout.titleBarHeight)
                
                HSplitView {
                    MacTextEditor(text: $viewModel.text)
                        .frame(minWidth: Layout.editorMinWidth)
                    
                    ResultsSidebar(lineResults: viewModel.lineResults)
                        .frame(minWidth: Layout.sidebarMinWidth)
                        .frame(maxWidth: 600, maxHeight: .infinity)
                        .overlay(
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 1),
                            alignment: .leading
                        )
                }
                
                StatusBar(lineResults: viewModel.lineResults)
            }
            
            CustomTitleBar(title: "Lime")
        }
        .ignoresSafeArea(edges: .top)
        .background(WindowAccessor())
    }
}

#Preview {
    ContentView()
}
