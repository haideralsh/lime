import SwiftUI

struct StatusBar: View {
    private enum Layout {
        static let height: CGFloat = 24
        static let horizontalPadding: CGFloat = 12
        static let fontSize: CGFloat = 12
    }
    
    let lineResults: [LineResult]
    
    private var total: Decimal {
        lineResults.compactMap { $0.value?.asDecimal }.reduce(0, +)
    }
    
    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 10
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: total)) ?? "\(total)"
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text("Total: \(formattedTotal)")
                .font(.system(size: Layout.fontSize, weight: .regular, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .frame(height: Layout.height)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.2))
    }
}

#Preview {
    StatusBar(lineResults: [
        LineResult(lineIndex: 0, sourceRange: NSRange(), value: .quantity(.scalar(42)), error: nil),
        LineResult(lineIndex: 1, sourceRange: NSRange(), value: nil, error: nil),
        LineResult(lineIndex: 2, sourceRange: NSRange(), value: .quantity(.scalar(123.456)), error: nil),
    ])
    .frame(width: 400)
}
