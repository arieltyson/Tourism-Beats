import Testing
@testable import Tourism_Beats

struct WikivoyageActivityGuideParserTests {
    @Test func parseSeeTemplateExtractsStructuredActivityFields() throws {
        let parser = WikivoyageActivityGuideParser()
        let wikitext = """
        ==See==
        ===Museums===
        * {{see
        | name=Viking Ship Museum and Historical Museum
        | url=https://www.vikingtidsmuseet.no/english/
        | address=Huk aveny 35
        | lat=59.90492
        | long=10.68444
        | hours=Daily
        | price=145 kr
        | wikidata=Q961220
        | wikipedia=Viking Ship Museum
        | content=Museum featuring the Tune, Oseberg and Gokstad Viking ships.
        }}
        """

        let activities = parser.activities(
            from: wikitext,
            guidePageTitle: "Oslo",
            topSectionTitle: "See"
        )

        #expect(activities.count == 1)

        let activity = try #require(activities.first)
        #expect(activity.name == "Viking Ship Museum and Historical Museum")
        #expect(activity.kind == .see)
        #expect(activity.category == "Museum")
        #expect(activity.officialURL?.absoluteString == "https://www.vikingtidsmuseet.no/english/")
        #expect(activity.sourceURL?.absoluteString == "https://en.wikivoyage.org/wiki/Oslo#Museums")
        #expect(activity.address == "Huk aveny 35")
        #expect(activity.hours == "Daily")
        #expect(activity.price == "145 kr")
        #expect(activity.latitude == 59.90492)
        #expect(activity.longitude == 10.68444)
        #expect(activity.wikidataIdentifier == "Q961220")
        #expect(activity.sourcePageTitle == "Viking Ship Museum")
        #expect(activity.sourceName == "Wikivoyage")
    }

    @Test func parseDoSectionExtractsSentenceBulletsAndTemplateListings() throws {
        let parser = WikivoyageActivityGuideParser()
        let wikitext = """
        ==Do==
        * Explore the archipelago of the Inner Oslofjord: Islands with many beaches and hiking trails are just waiting to be discovered.

        ===Music===
        * {{do
        | name=Oslo Jazz Festival
        | url=https://www.oslojazz.no
        | wikidata=Q11994226
        | content=Taking place mid-August in various venues, downtown.
        }}
        """

        let activities = parser.activities(
            from: wikitext,
            guidePageTitle: "Oslo",
            topSectionTitle: "Do"
        )

        #expect(activities.count == 2)

        let archipelago = try #require(
            activities.first { $0.name == "Archipelago of the Inner Oslofjord" }
        )
        #expect(archipelago.kind == .do)
        #expect(archipelago.sourceName == "Wikivoyage")

        let festival = try #require(
            activities.first { $0.name == "Oslo Jazz Festival" }
        )
        #expect(festival.kind == .do)
        #expect(festival.category == "Music")
        #expect(festival.officialURL?.absoluteString == "https://www.oslojazz.no")
        #expect(festival.wikidataIdentifier == "Q11994226")
        #expect(festival.sourceURL?.absoluteString == "https://en.wikivoyage.org/wiki/Oslo#Music")
    }

    @Test func parseInlineTemplateListingDoesNotLeakParameterMarkupIntoName() throws {
        let parser = WikivoyageActivityGuideParser()
        let wikitext = """
        ==See==
        ===Museums===
        * {{see|name=[[Museo Nacional de Etnografía y Folklore|National Ethnographic and Folk Museum]]|alt=Museo Nacional de Etnografía y Folklore|url=http://www.musef.org.bo/|email=|content=Folklore museum in central La Paz.}}
        """

        let activities = parser.activities(
            from: wikitext,
            guidePageTitle: "La Paz",
            topSectionTitle: "See"
        )

        #expect(activities.count == 1)

        let activity = try #require(activities.first)
        #expect(activity.name == "National Ethnographic and Folk Museum")
        #expect(activity.officialURL?.absoluteString == "http://www.musef.org.bo/")
        #expect(activity.summary == "Folklore museum in central La Paz.")
        #expect(activity.name.contains("alt=") == false)
        #expect(activity.name.contains("url=") == false)
        #expect(activity.name.contains("email=") == false)
    }
}
