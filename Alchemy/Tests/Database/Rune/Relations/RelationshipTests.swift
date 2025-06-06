@testable
import Alchemy
import AlchemyTesting

@Suite(.mockTestApp)
struct RelationshipTests {
    private var organization: Organization!
    private var user: User!
    private var repository: Repository!
    private var workflow: Workflow!
    private var job: Job!

    init() async throws {
        try await DB.migrate([WorkflowMigration()])

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

        organization = try await Organization().id(1).insertReturn()
        try await Organization().id(2).insert()
        user = try await User(name: "Josh", age: 29, managerId: nil).id(3).insertReturn()
        try await User(name: "Bill", age: 35, managerId: 3).id(4).insert()
        try await UserOrganization(userId: 3, organizationId: 1).insert()
        try await UserOrganization(userId: 3, organizationId: 2).insert()
        try await UserOrganization(userId: 4, organizationId: 1).insert()
        try await UserOrganization(userId: 4, organizationId: 2).insert()
        repository = try await Repository(userId: 3).id(5).insertReturn()
        try await Repository(userId: 3).id(6).insert()
        workflow = try await Workflow(repositoryId: 5).id(7).insertReturn()
        try await Workflow(repositoryId: 5).id(8).insert()
        job = try await Job(workflowId: 7).id(9).insertReturn()
        try await Job(workflowId: 7).id(10).insert()
    }

    // MARK: Basics

    @Test func hasMany() async throws {
        let repositories = try await user.refresh().repositories
        #expect(repositories.map(\.id) == [5, 6])
    }

    @Test func hasOne() async throws {
        let manager = try await user.report
        #expect(manager?.id == 4)
    }

    @Test func belongsTo() async throws {
        let user = try await repository.user
        #expect(user.id == 3)
    }

    @Test func through() async throws {
        let jobs = try await user.jobs.get()
        #expect(jobs.map(\.id) == [9, 10])
    }

    @Test func pivot() async throws {
        let organizations = try await user.organizations
        #expect(organizations.map(\.id) == [1, 2])
    }

    @Test func fetchWhere() async throws {
        let organizations = try await organization.usersOver30.get()
        #expect(organizations.map(\.id) == [4])
    }

    // MARK: - Eager Loading

    @Test func eagerLoad() async throws {
        let user = try await User.where("id" == 3).with(\.$repositories).first()
        #expect(user != nil)
        #expect(throws: Never.self) { try user?.$repositories.require() }
    }

    @Test func autoCache() async throws {
        #expect(throws: Error.self) { try user.$repositories.require() }
        _ = try await user.$repositories.value()
        #expect(user.$repositories.isLoaded == true)
        #expect(throws: Never.self) { try user.$repositories.require() }
    }

    @Test func whereCache() async throws {
        _ = try await organization.users
        #expect(organization.$users.isLoaded == true)
        #expect(organization.usersOver30.isLoaded == false)
    }

    @Test func sync() async throws {
        let report = try await user.report
        #expect(report?.id == 4)
        try await report?.update(["manager_id": SQLValue.null])
        #expect(user.$report.isLoaded == true)
        #expect(try await user.report?.id == 4)
        #expect(try await user.$report.load() == nil)
    }

    // MARK: - CRUD

    @Test(.disabled())
    func pivotAdd() async throws {
    }

    @Test(.disabled())
    func pivotRemove() async throws {
    }

    @Test(.disabled())
    func pivotRemoveAll() async throws {
    }

    @Test(.disabled())
    func pivotReplace() async throws {
    }
}

@Model
private struct Organization {
    var id: Int

    @BelongsToMany(UserOrganization.table) var users: [User]

    var usersOver30: BelongsToMany<[User]> {
        belongsToMany(UserOrganization.table)
            .where("age" >= 30)
    }
}

@Model
private struct UserOrganization {
    var id: Int
    var userId: Int
    var organizationId: Int
}

@Model
private struct User {
    var id: Int
    let name: String
    let age: Int
    var managerId: Int?

    @HasOne(to: "manager_id") var report: User?
    @HasMany var repositories: [Repository]

    var jobs: HasManyThrough<[Job]> {
        hasMany(to: "workflow_id")
            .through(Repository.table, from: "user_id", to: "id")
            .through(Workflow.table, from: "repository_id", to: "id")
    }

    @BelongsToMany(UserOrganization.table) var organizations: [Organization]
}

@Model
private struct Repository {
    var id: Int
    var userId: Int

    @BelongsTo var user: User
    @HasMany var workflows: [Workflow]
}

@Model
private struct Workflow {
    var id: Int
    var repositoryId: Int

    @BelongsTo var repository: Repository
    @HasMany var jobs: [Job]
}

@Model
private struct Job {
    var id: Int
    var workflowId: Int

    @BelongsTo var workflow: Workflow

    var user: BelongsToThrough<User> {
        belongsTo()
            .through(Workflow.table)
            .through(Repository.table)
    }
}

@Model
private struct TestModel {
    var id: Int
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
