@testable
import Alchemy
import AlchemyTest

final class RelationshipNewTests: TestCase<TestApp> {
    private var organization: Organization!
    private var user: User!
    private var repository: Repository!
    private var workflow: Workflow!
    private var job: Job!

    override func setUp() async throws {
        try await super.setUp()
        try await Database.fake(migrations: [WorkflowMigration()])

        /*
         ============ TODO =============
         1. Default keys for throughs.
            Assume each relationship
            same as parent.
         2. Relationship CRUD. Constrain
            to pivot relationships only.
         ===============================
         */

        /*
         ========== STRUCTURE ==========
         organizations              1   2
                                     \ /
         user_organizations           X   M-M
                                     / \
         users                      3 - 4
                                   / \    1-M
         repositories             5   6
                                 / \      1-M
         workflows              7   8
                               / \        1-M
         jobs                 9  10
         ===============================
         */
        organization = try await Organization(id: 1).insertReturn()
        try await Organization(id: 2).insert()
        user = try await User(id: 3, name: "Josh", age: 29, managerId: nil).insertReturn()
        try await User(id: 4, name: "Bill", age: 35, managerId: 3).insert()
        try await UserOrganization(userId: 3, organizationId: 1).insert()
        try await UserOrganization(userId: 3, organizationId: 2).insert()
        try await UserOrganization(userId: 4, organizationId: 1).insert()
        try await UserOrganization(userId: 4, organizationId: 2).insert()
        repository = try await Repository(id: 5, userId: 3).insertReturn()
        try await Repository(id: 6, userId: 3).insert()
        workflow = try await Workflow(id: 7, repositoryId: 5).insertReturn()
        try await Workflow(id: 8, repositoryId: 5).insert()
        job = try await Job(id: 9, workflowId: 7).insertReturn()
        try await Job(id: 10, workflowId: 7).insert()
    }

    // MARK: - Basics

    func testHasMany() async throws {
        let repositories = try await user.sync().repositories.fetch()
        XCTAssertEqual(repositories.map(\.id), [5, 6])
    }

    func testHasOne() async throws {
        let manager = try await user.report.fetch()
        XCTAssertEqual(manager?.id, 4)
    }

    func testBelongsTo() async throws {
        let user = try await repository.user.fetch()
        XCTAssertEqual(user.id, 3)
    }

    func testThrough() async throws {
        let jobs = try await user.jobs.fetch()
        XCTAssertEqual(jobs.map(\.id), [9, 10])
    }

    func testPivot() async throws {
        let organizations = try await user.organizations.fetch()
        XCTAssertEqual(organizations.map(\.id), [1, 2])
    }

    func testFetchWhere() async throws {
        let organizations = try await organization.usersOver30.fetch()
        XCTAssertEqual(organizations.map(\.id), [4])
    }

    // MARK: - Eager Loading

    func testEagerLoad() async throws {
        let user = try await User.where("id" == 3).with(\.repositories).first()
        XCTAssertNotNil(user)
        XCTAssertNoThrow(try user?.repositories.require())
    }

    func testAutoCache() async throws {
        XCTAssertThrowsError(try user.repositories.require())
        _ = try await user.repositories.fetch()
        XCTAssertTrue(user.repositories.isLoaded)
        XCTAssertNoThrow(try user.repositories.require())
    }

    func testWhereCache() async throws {
        _ = try await organization.users.fetch()
        XCTAssertTrue(organization.users.isLoaded)
        XCTAssertFalse(organization.usersOver30.isLoaded)
    }

    func testSync() async throws {
        let report = try await user.report.fetch()
        XCTAssertEqual(report?.id, 4)
        try await report?.update(with: ["manager_id": SQLValue.null])
        XCTAssertTrue(user.report.isLoaded)
        AssertEqual(try await user.report.fetch()?.id, 4)
        AssertNil(try await user.report.sync())
    }

    // MARK: - CRUD

    func testPivotAdd() async throws {
        let newOrganization = try await Organization(id: 3).insertReturn()
        try await user.organizations.add(newOrganization)
        throw XCTSkip()
    }

    func testPivotRemove() async throws {
        try await user.organizations.remove(organization)
        throw XCTSkip()
    }

    func testPivotRemoveAll() async throws {
        try await user.organizations.removeAll()
        throw XCTSkip()
    }

    func testPivotReplace() async throws {
        let newOrganization = try await Organization(id: 4).insertReturn()
        try await user.organizations.replace([newOrganization])
        throw XCTSkip()
    }
}

private struct Organization: Model, EagerLoadable {
    var cache: ModelCache?

    var id: Int?

    var users: Relationship2<[User]> {
        hasMany()
            .throughPivot(UserOrganization.self)
    }

    var usersOver30: Relationship2<[User]> {
        hasMany()
            .throughPivot(UserOrganization.self)
            .where("age" >= 30)
    }
}

private struct UserOrganization: Model {
    var id: Int?
    var userId: Int
    var organizationId: Int
}

private struct User: Model, EagerLoadable {
    var cache: ModelCache?

    var id: Int?
    let name: String
    let age: Int
    var managerId: Int?

    var report: Relationship2<User?> {
        hasOne(to: "manager_id")
    }

    var repositories: Relationship2<[Repository]> {
        hasMany()
    }

    var jobs: Relationship2<[Job]> {
        hasMany(to: "workflow_id")
            .through(Repository.self, from: "user_id", to: "id")
            .through(Workflow.self, from: "repository_id", to: "id")
    }

    var organizations: Relationship2<[Organization]> {
        hasMany()
            .throughPivot(UserOrganization.self)
    }
}

private struct Repository: Model, EagerLoadable {
    var cache: ModelCache?

    var id: Int?
    var userId: Int

    var user: Relationship2<User> {
        belongsTo()
    }

    var workflows: Relationship2<[Workflow]> {
        hasMany()
    }
}

private struct Workflow: Model, EagerLoadable {
    var cache: ModelCache?

    var id: Int?
    var repositoryId: Int

    var repository: Relationship2<Repository> {
        belongsTo()
    }

    var jobs: Relationship2<[Job]> {
        hasMany()
    }
}

private struct Job: Model, EagerLoadable {
    var cache: ModelCache?

    var id: Int?
    var workflowId: Int

    var workflow: Relationship2<Workflow> {
        belongsTo()
    }

    var user: Relationship2<User> {
        belongsTo()
            .through(Workflow.self)
            .through(Repository.self)
    }
}

private struct TestModel: Model, Equatable {
    var id: Int?
}

private struct WorkflowMigration: Migration {
    func up(schema: Schema) {
        schema.create(table: "organizations") {
            $0.increments("id").primary()
        }

        schema.create(table: "user_organizations") {
            $0.increments("id").primary()
            $0.bigInt("user_id").references("id", on: "users")
            $0.bigInt("organization_id").references("id", on: "organizations")
        }

        schema.create(table: "users") {
            $0.increments("id").primary()
            $0.string("name").notNull()
            $0.int("age").notNull()
            $0.bigInt("manager_id").references("id", on: "users")
        }

        schema.create(table: "repositories") {
            $0.increments("id").primary()
            $0.bigInt("user_id").references("id", on: "users")
        }

        schema.create(table: "workflows") {
            $0.increments("id").primary()
            $0.bigInt("repository_id").references("id", on: "repositories")
        }

        schema.create(table: "jobs") {
            $0.increments("id").primary()
            $0.bigInt("workflow_id").references("id", on: "workflows")
        }
    }

    func down(schema: Schema) {
        schema.drop(table: "users")
        schema.drop(table: "repositories")
        schema.drop(table: "workflows")
        schema.drop(table: "jobs")
    }
}
