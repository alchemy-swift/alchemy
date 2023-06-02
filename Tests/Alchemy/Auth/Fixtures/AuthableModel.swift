import Alchemy

struct AuthModel: BasicAuthable {
    var id: PK<Int> = .new
    let email: String
    let password: String
    
    struct Migrate: Migration {
        func up(schema: Schema) {
            schema.create(table: AuthModel.tableName) {
                $0.increments("id")
                    .primary()
                $0.string("email")
                    .notNull()
                    .unique()
                $0.string("password")
                    .notNull()
            }
        }
        
        func down(schema: Schema) {
            schema.drop(table: AuthModel.tableName)
        }
    }
}

struct TokenModel: Model, TokenAuthable {
    static var userKey = \TokenModel.$authModel
    
    var id: PK<Int> = .new
    var value = UUID()
    
    @BelongsTo
    var authModel: AuthModel
    
    struct Migrate: Migration {
        func up(schema: Schema) {
            schema.create(table: TokenModel.tableName) {
                $0.increments("id")
                    .primary()
                $0.uuid("value")
                    .notNull()
                $0.bigInt("auth_model_id")
                    .notNull()
                    .references("id", on: "auth_models")
            }
        }
        
        func down(schema: Schema) {
            schema.drop(table: TokenModel.tableName)
        }
    }
}
