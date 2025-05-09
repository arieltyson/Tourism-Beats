import SwiftUI

struct FutureUpdatesViewControllerWrapper: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> FutureUpdatesViewController {
            return FutureUpdatesViewController()
        }
        
        func updateUIViewController(_ uiViewController: FutureUpdatesViewController, context: Context) {}
    }
