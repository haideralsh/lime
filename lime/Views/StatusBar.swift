import SwiftUI

struct StatusBar: View {
    private enum Layout {
        static let height: CGFloat = 24
        static let horizontalPadding: CGFloat = 12
        static let fontSize: CGFloat = 12
    }
    
    let sum: Decimal
    
    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 10
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: sum)) ?? "\(sum)"
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text("Total: \(formattedTotal)")
                .font(.system(size: Layout.fontSize, weight: .regular, design: .default))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .frame(height: Layout.height)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.2))
    }
}

#Preview {
    StatusBar(sum: Decimal(165.456))
    .frame(width: 400)
}
