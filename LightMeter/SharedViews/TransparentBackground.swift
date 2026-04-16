import SwiftUI

/// A UIViewRepresentable that walks the UIKit view hierarchy and clears
/// the background color of all ancestor views. This makes SwiftUI's
/// TabView content area transparent so views behind it (like a shared
/// CameraPreviewView) can show through.
///
/// SwiftUI's TabView wraps each tab in a UIHostingController whose view
/// has a default opaque system background. There is no public SwiftUI
/// modifier to clear it. This workaround traverses the superview chain
/// and sets backgroundColor to .clear on each ancestor.
struct TransparentBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = TransparentBackgroundUIView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

private class TransparentBackgroundUIView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Walk up the superview chain and clear backgrounds.
        // This catches the UIHostingView and any intermediate containers
        // that SwiftUI's TabView inserts.
        var current = superview
        while let view = current {
            view.backgroundColor = .clear
            current = view.superview
        }
    }
}
