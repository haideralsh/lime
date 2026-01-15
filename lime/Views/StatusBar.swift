import SwiftUI

struct StatusBar: View {
    private enum Layout {
        static let height: CGFloat = 24
        static let horizontalPadding: CGFloat = 12
        static let fontSize: CGFloat = 12
    }
    
    let sum: Decimal
    let copiedMessage: String?
    var onTotalTap: (() -> Void)? = nil
    
    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 10
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: sum)) ?? "\(sum)"
    }
    
    var body: some View {
        HStack {
            if let copiedMessage {
                Text(copiedMessage)
                    .font(.system(size: Layout.fontSize, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("Total: \(formattedTotal)")
                .font(.system(size: Layout.fontSize, weight: .regular, design: .default))
                .foregroundColor(.secondary)
                .onTapGesture {
                    onTotalTap?()
                }
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .frame(height: Layout.height)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.2))
    }
}

#Preview {
    StatusBar(sum: Decimal(165.456), copiedMessage: "Copied to clipboard", onTotalTap: {})
    .frame(width: 400)
}
