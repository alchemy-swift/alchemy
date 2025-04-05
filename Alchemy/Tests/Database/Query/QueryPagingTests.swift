@testable
import Alchemy
import AlchemyTesting

struct QueryPagingTests {
    @Test func limit() {
        #expect(TestQuery("foo").distinct().isDistinct == true)
    }

    @Test func offset() {
        #expect(TestQuery("foo").distinct().isDistinct == true)
    }

    @Test func paging() {
        let standardPage = TestQuery("foo").page(4)
        #expect(standardPage.limit == 100)
        #expect(standardPage.offset == 300)

        let customPage = TestQuery("foo").page(2, pageSize: 10)
        #expect(customPage.limit == 10)
        #expect(customPage.offset == 10)
    }
}
