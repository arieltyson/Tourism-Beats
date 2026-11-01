import Foundation

// MARK: - RestaurantCuisine

/// What a journal restaurant serves. Raw values are persisted, so existing
/// cases must never be renamed.
enum RestaurantCuisine: String, CaseIterable, Identifiable, Sendable {
    case american
    case bakery
    case bar
    case bistro
    case brazilian
    case breakfast
    case brunch
    case bubbleTea
    case burgers
    case cafe
    case californian
    case caribbean
    case chinese
    case coffee
    case dessert
    case english
    case ethiopian
    case fastFood
    case french
    case fusion
    case german
    case greek
    case indian
    case international
    case italian
    case japanese
    case juice
    case korean
    case lebanese
    case mediterranean
    case mexican
    case middleEastern
    case other
    case persian
    case peruvian
    case pizza
    case portuguese
    case russian
    case seafood
    case snack
    case spanish
    case steakhouse
    case sushi
    case tea
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
        case .bar:
            "Bar"
        case .bistro:
            "Bistro"
        case .brazilian:
            "Brazilian"
        case .breakfast:
            "Breakfast"
        case .brunch:
            "Brunch"
        case .bubbleTea:
            "Bubble Tea"
        case .burgers:
            "Burgers"
        case .cafe:
            "Cafe"
        case .californian:
            "Californian"
        case .caribbean:
            "Caribbean"
        case .chinese:
            "Chinese"
        case .coffee:
            "Coffee"
        case .dessert:
            "Dessert"
        case .english:
            "English"
        case .ethiopian:
            "Ethiopian"
        case .fastFood:
            "Fast Food"
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
        case .juice:
            "Juice & Smoothies"
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
        case .pizza:
            "Pizza"
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
        case .sushi:
            "Sushi"
        case .tea:
            "Tea & Matcha"
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

    /// The group the cuisine is listed under when choosing one.
    var category: RestaurantCuisineCategory {
        switch self {
        case .bar, .bubbleTea, .cafe, .coffee, .juice, .tea:
            .drinks
        case .bakery, .dessert:
            .sweets
        case .breakfast, .brunch, .bistro, .burgers, .fastFood, .fusion, .international,
             .other, .pizza, .seafood, .snack, .steakhouse, .sushi, .vegan, .vegetarian:
            .dining
        case .american, .brazilian, .californian, .caribbean, .chinese, .english,
             .ethiopian, .french, .german, .greek, .indian, .italian, .japanese, .korean,
             .lebanese, .mediterranean, .mexican, .middleEastern, .persian, .peruvian,
             .portuguese, .russian, .spanish, .thai, .turkish, .vietnamese:
            .world
        }
    }

    /// Other words people search for the cuisine by, beyond its label.
    var searchKeywords: [String] {
        switch self {
        case .bubbleTea:
            ["Boba", "Milk Tea"]
        case .coffee:
            ["Espresso", "Latte", "Roastery"]
        case .juice:
            ["Smoothie", "Açaí", "Cold Pressed"]
        case .tea:
            ["Matcha", "Chai"]
        case .bar:
            ["Cocktails", "Wine", "Beer", "Pub"]
        case .dessert:
            ["Ice Cream", "Gelato"]
        case .bakery:
            ["Pastry", "Patisserie"]
        default:
            []
        }
    }
}
