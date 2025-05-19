import SwiftUI

struct UnsupportedOSViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UnsupportedOSViewController {
        return UnsupportedOSViewController()
    }
    
    func updateUIViewController(_ uiViewController: UnsupportedOSViewController, context: Context) {}
}
