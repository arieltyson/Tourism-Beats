struct CustomNavigationTitle: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
    }
}

extension View {
    func customNavigationTitle(_ title: String) -> some View {
        self.modifier(CustomNavigationTitle(title: title))
    }
}