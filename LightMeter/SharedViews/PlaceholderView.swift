import SwiftUI

struct PlaceholderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: DesignConstants.spacingSM) {
                Text(title)
                    .font(DesignConstants.fontTitle)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(DesignConstants.fontSM)
                    .foregroundColor(.gray)
            }
        }
    }
}
