import Foundation

enum RestaurantCuisine: String, CaseIterable, Identifiable, Sendable {
    case american
    case bakery
    case brazilian
    case cafe
    case caribbean
    case chinese
    case dessert
    case english
    case ethiopian
    case french
    case fusion
    case german
    case greek
    case indian
    case international
    case italian
    case japanese
    case korean
    case lebanese
    case mediterranean
    case mexican
    case middleEastern
    case other
    case persian
    case peruvian
    case portuguese
    case russian
    case seafood
    case snack
    case spanish
    case steakhouse
    case thai
    case turkish
    case vegan
    case vegetarian
    case vietnamese

    var id: String { self.rawValue }

    var label: String {
        switch self {
        case .american:
            "American"
        case .bakery:
            "Bakery"
        case .brazilian:
            "Brazilian"
        case .cafe:
            "Cafe"
        case .caribbean:
            "Caribbean"
        case .chinese:
            "Chinese"
        case .dessert:
            "Dessert"
        case .english:
            "English"
        case .ethiopian:
            "Ethiopian"
        case .french:
            "French"
        case .fusion:
            "Fusion"
        case .german:
            "German"
        case .greek:
            "Greek"
        case .indian:
            "Indian"
        case .international:
            "International"
        case .italian:
            "Italian"
        case .japanese:
            "Japanese"
        case .korean:
            "Korean"
        case .lebanese:
            "Lebanese"
        case .mediterranean:
            "Mediterranean"
        case .mexican:
            "Mexican"
        case .middleEastern:
            "Middle Eastern"
        case .other:
            "Other"
        case .persian:
            "Persian"
        case .peruvian:
            "Peruvian"
        case .portuguese:
            "Portuguese"
        case .russian:
            "Russian"
        case .seafood:
            "Seafood"
        case .snack:
            "Snack"
        case .spanish:
            "Spanish"
        case .steakhouse:
            "Steakhouse"
        case .thai:
            "Thai"
        case .turkish:
            "Turkish"
        case .vegan:
            "Vegan"
        case .vegetarian:
            "Vegetarian"
        case .vietnamese:
            "Vietnamese"
        }
    }
}
