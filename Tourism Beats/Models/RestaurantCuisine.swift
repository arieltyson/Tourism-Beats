import Foundation

enum RestaurantCuisine: String, CaseIterable, Identifiable, Sendable {
    case american
    case international
    case italian
    case french
    case spanish
    case mediterranean
    case middleEastern
    case greek
    case turkish
    case lebanese
    case persian
    case mexican
    case peruvian
    case brazilian
    case caribbean
    case japanese
    case chinese
    case korean
    case thai
    case vietnamese
    case indian
    case ethiopian
    case seafood
    case steakhouse
    case vegetarian
    case vegan
    case fusion
    case cafe
    case bakery
    case dessert
    case other

    var id: String { self.rawValue }

    var label: String {
        switch self {
        case .american:
            "American"
        case .international:
            "International"
        case .italian:
            "Italian"
        case .french:
            "French"
        case .spanish:
            "Spanish"
        case .mediterranean:
            "Mediterranean"
        case .middleEastern:
            "Middle Eastern"
        case .greek:
            "Greek"
        case .turkish:
            "Turkish"
        case .lebanese:
            "Lebanese"
        case .persian:
            "Persian"
        case .mexican:
            "Mexican"
        case .peruvian:
            "Peruvian"
        case .brazilian:
            "Brazilian"
        case .caribbean:
            "Caribbean"
        case .japanese:
            "Japanese"
        case .chinese:
            "Chinese"
        case .korean:
            "Korean"
        case .thai:
            "Thai"
        case .vietnamese:
            "Vietnamese"
        case .indian:
            "Indian"
        case .ethiopian:
            "Ethiopian"
        case .seafood:
            "Seafood"
        case .steakhouse:
            "Steakhouse"
        case .vegetarian:
            "Vegetarian"
        case .vegan:
            "Vegan"
        case .fusion:
            "Fusion"
        case .cafe:
            "Cafe"
        case .bakery:
            "Bakery"
        case .dessert:
            "Dessert"
        case .other:
            "Other"
        }
    }
}
