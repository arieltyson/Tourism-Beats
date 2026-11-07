// MARK: - BucketListItemKind

/// What a bucket list item is: somewhere to go, or something to do.
enum BucketListItemKind: String, CaseIterable, Identifiable, Sendable {
    case place
    case activity

    var id: Self { self }

    var title: String {
        switch self {
        case .place: "Place"
        case .activity: "Activity"
        }
    }

    /// The question the add form asks for this kind.
    var prompt: String {
        switch self {
        case .place: "Where do you want to go?"
        case .activity: "What do you want to do?"
        }
    }

    var systemImage: String {
        switch self {
        case .place: "globe.americas.fill"
        case .activity: "figure.hiking"
        }
    }
}
