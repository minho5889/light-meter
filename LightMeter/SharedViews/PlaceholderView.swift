import SwiftUI

struct PlaceholderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: DesignConstants.spacingSM) {
                Text(title)
                    .font(.system(size: DesignConstants.fontSizeTitle, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: DesignConstants.fontSizeSM))
                    .foregroundColor(.gray)
            }
        }
    }
}
