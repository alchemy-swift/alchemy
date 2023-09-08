@testable
import Alchemy
import AlchemyTest

final class RelationTests: TestCase<TestApp> {
    private var organization: Organization!
    private var user: User!
    private var repository: Repository!
    private var workflow: Workflow!
    private var job: Job!

    override func setUp() async throws {
        try await super.setUp()
        try await Database.fake(migrations: [WorkflowMigration()])

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
        let repositories = try await user.refresh().repositories.get()
        XCTAssertEqual(repositories.map(\.id), [5, 6])
    }

    func testHasOne() async throws {
        let manager = try await user.report()
        XCTAssertEqual(manager?.id, 4)
    }

    func testBelongsTo() async throws {
        let user = try await repository.user()
        XCTAssertEqual(user.id, 3)
    }

    func testThrough() async throws {
        let jobs = try await user.jobs.get()
        XCTAssertEqual(jobs.map(\.id), [9, 10])
    }

    func testPivot() async throws {
        let organizations = try await user.organizations.value()
        XCTAssertEqual(organizations.map(\.id), [1, 2])
    }

    func testFetchWhere() async throws {
        let organizations = try await organization.usersOver30.get()
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
        _ = try await user.repositories.value()
        XCTAssertTrue(user.repositories.isLoaded)
        XCTAssertNoThrow(try user.repositories.require())
    }

    func testWhereCache() async throws {
        _ = try await organization.users.value()
        XCTAssertTrue(organization.users.isLoaded)
        XCTAssertFalse(organization.usersOver30.isLoaded)
    }

    func testSync() async throws {
        let report = try await user.report()
        XCTAssertEqual(report?.id, 4)
        try await report?.update(["manager_id": SQLValue.null])
        XCTAssertTrue(user.report.isLoaded)
        AssertEqual(try await user.report()?.id, 4)
        AssertNil(try await user.report.load())
    }

    // MARK: - CRUD

    func testPivotAdd() async throws {
        throw XCTSkip()
    }

    func testPivotRemove() async throws {
        throw XCTSkip()
    }

    func testPivotRemoveAll() async throws {
        throw XCTSkip()
    }

    func testPivotReplace() async throws {
        throw XCTSkip()
    }
}

private struct Organization: Model, Codable {
    var id: PK<Int> = .new

    var users: BelongsToMany<User> {
        belongsToMany(pivot: UserOrganization.table)
    }

    var usersOver30: BelongsToMany<User> {
        belongsToMany(pivot: UserOrganization.table)
            .where("age" >= 30)
    }
}

private struct UserOrganization: Model, Codable {
    var id: PK<Int> = .new
    var userId: Int
    var organizationId: Int
}

private struct User: Model, Codable {
    var id: PK<Int> = .new
    let name: String
    let age: Int
    var managerId: Int?

    var report: HasOne<User?> {
        hasOne(to: "manager_id")
    }

    var repositories: HasMany<Repository> {
        hasMany()
    }

    var jobs: HasManyThrough<Job> {
        hasMany(to: "workflow_id")
            .through(Repository.table, from: "user_id", to: "id")
            .through(Workflow.table, from: "repository_id", to: "id")
    }

    var organizations: BelongsToMany<Organization> {
        belongsToMany(pivot: UserOrganization.table)
    }
}

private struct Repository: Model, Codable {
    var id: PK<Int> = .new
    var userId: Int

    var user: BelongsTo<User> {
        belongsTo()
    }

    var workflows: HasMany<Workflow> {
        hasMany()
    }
}

private struct Workflow: Model, Codable {
    var id: PK<Int> = .new
    var repositoryId: Int

    var repository: BelongsTo<Repository> {
        belongsTo()
    }

    var jobs: HasMany<Job> {
        hasMany()
    }
}

private struct Job: Model, Codable {
    var id: PK<Int> = .new
    var workflowId: Int

    var workflow: BelongsTo<Workflow> {
        belongsTo()
    }

    var user: BelongsToThrough<User> {
        belongsTo()
            .through(Workflow.table)
            .through(Repository.table)
    }
}

private struct TestModel: Model, Codable {
    var id: PK<Int> = .new
}

private struct WorkflowMigration: Migration {
    func up(db: Database) async throws {
        try await db.createTable("organizations") {
            $0.increments("id").primary()
        }

        try await db.createTable("user_organizations") {
            $0.increments("id").primary()
            $0.bigInt("user_id").references("id", on: "users")
            $0.bigInt("organization_id").references("id", on: "organizations")
        }

        try await db.createTable("users") {
            $0.increments("id").primary()
            $0.string("name").notNull()
            $0.int("age").notNull()
            $0.bigInt("manager_id").references("id", on: "users")
        }

        try await db.createTable("repositories") {
            $0.increments("id").primary()
            $0.bigInt("user_id").references("id", on: "users")
        }

        try await db.createTable("workflows") {
            $0.increments("id").primary()
            $0.bigInt("repository_id").references("id", on: "repositories")
        }

        try await db.createTable("jobs") {
            $0.increments("id").primary()
            $0.bigInt("workflow_id").references("id", on: "workflows")
        }
    }

    func down(db: Database) async throws {
        try await db.dropTable("users")
        try await db.dropTable("repositories")
        try await db.dropTable("workflows")
        try await db.dropTable("jobs")
    }
}
