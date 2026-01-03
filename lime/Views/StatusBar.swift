import SwiftUI

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
        .background(Color.gray.opacity(Layout.backgroundOpacity))
    }
}

#Preview {
    StatusBar(characterCount: 42)
        .frame(width: 400)
}

