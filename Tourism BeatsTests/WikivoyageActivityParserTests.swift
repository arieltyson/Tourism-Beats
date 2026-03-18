import Testing
@testable import Tourism_Beats

struct WikivoyageActivityParserTests {
    @Test func parsesMainGuideListingIntoActivityModel() {
        let parser = WikivoyageActivityParser()
        let wikitext = """
        ==See==
        ===Landmarks===
        * {{see
        | name=[[Paris/7th arrondissement#Q243|Eiffel Tower]]
        | url=https://www.toureiffel.paris/
        | lat=48.858
        | long=2.2953
        | image=Tour Eiffel Wikimedia Commons.jpg
        | content=No other monument better symbolizes Paris.
        | wikidata=Q243
        }}
        """

        let activities = parser.activities(
            from: wikitext,
            defaultKind: .see,
            sourcePageTitle: "Paris"
        )

        #expect(activities.count == 1)

        let activity = activities[0]
        #expect(activity.name == "Eiffel Tower")
        #expect(activity.kind == .see)
        #expect(activity.category == "Landmarks")
        #expect(activity.summary == "No other monument better symbolizes Paris.")
        #expect(activity.sourcePageTitle == "Paris/7th arrondissement")
        #expect(activity.sourceAnchor == "Q243")
        #expect(activity.officialURL?.absoluteString == "https://www.toureiffel.paris/")
        #expect(activity.imageURL != nil)
        #expect(activity.sourceURL?.absoluteString.contains("Paris/7th_arrondissement") == true)
    }

    @Test func parsesListingTemplateWithPracticalFields() {
        let parser = WikivoyageActivityParser()
        let wikitext = """
        ==Do==
        ===Photography===
        * {{listing | type=do
        | name=Maison Européene de la Photographie
        | url=https://www.mep-fr.org/english/
        | hours=W-Su 11:00-20:00
        | price=Admission €9
        | content=Important center for contemporary photography with a large exposition area.
        }}
        """

        let activities = parser.activities(
            from: wikitext,
            defaultKind: .do,
            sourcePageTitle: "Paris"
        )

        #expect(activities.count == 1)

        let activity = activities[0]
        #expect(activity.kind == .do)
        #expect(activity.category == "Photography")
        #expect(activity.price == "Admission €9")
        #expect(activity.hours == "W-Su 11:00-20:00")
        #expect(activity.timingTip == "Published hours: W-Su 11:00-20:00")
        #expect(activity.summary.localizedStandardContains("contemporary photography"))
    }
}
