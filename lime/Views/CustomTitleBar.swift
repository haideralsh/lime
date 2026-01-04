import SwiftUI

struct CustomTitleBar: View {
    private enum Layout {
        static let height: CGFloat = 28
        static let trafficLightWidth: CGFloat = 80
        static let fontSize: CGFloat = 13
    }
    
    let title: String
    
    var body: some View {
        ZStack {
            WindowDragView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: Layout.trafficLightWidth)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: Layout.fontSize))
                    .foregroundColor(.secondary)
                    .allowsHitTesting(false)
                
                Spacer()
                
                Color.clear
                    .frame(width: Layout.trafficLightWidth)
            }
        }
        .frame(height: Layout.height)
        .background(Color(white: 0.2))
    }
}

#Preview {
    CustomTitleBar(title: "Preview Title")
        .frame(width: 400)
}

