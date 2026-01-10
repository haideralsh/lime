import SwiftUI

struct ResultsSidebar: View {
    private enum Layout {
        static let fontSize: CGFloat = 24
        static let lineHeight: CGFloat = 29.25
        static let topPadding: CGFloat = 40
        static let horizontalPadding: CGFloat = 16
    }
    
    let lineResults: [LineResult]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(Array(lineResults.enumerated()), id: \.offset) { index, result in
                        resultRow(for: result)
                            .frame(height: Layout.lineHeight)
                    }
                }
                .padding(.top, Layout.topPadding)
                .padding(.horizontal, Layout.horizontalPadding)
                .frame(minWidth: geometry.size.width, alignment: .trailing)
            }
        }
        .background(Color(red: 0x18/255.0, green: 0x19/255.0, blue: 0x17/255.0))
    }
    
    @ViewBuilder
    private func resultRow(for result: LineResult) -> some View {
        HStack {
            Spacer()
            
            if let displayString = result.displayString {
                Text(displayString)
                    .font(.system(size: Layout.fontSize, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
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
