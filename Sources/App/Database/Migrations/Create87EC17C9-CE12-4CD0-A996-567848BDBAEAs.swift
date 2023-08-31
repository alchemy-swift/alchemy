import Alchemy

struct Create87EC17C9-CE12-4CD0-A996-567848BDBAEAs: Migration {
    func up(schema: Schema) {
        schema.create(table: "87_ec17c9-ce12-4cd0-a996-567848bdbaeas") {
            $0.increments("id").primary()
			$0.string("email").notNull().unique()
			$0.string("password").notNull()
			$0.bigint("parent_id").references("id", on: "users")
			$0.uuid("uuid").notNull()
			$0.double("double").notNull()
			$0.bool("bool").notNull()
			$0.date("date").notNull()
			$0.json("json").notNull()
        }
    }
    
    func down(schema: Schema) {
        schema.drop(table: "87_ec17c9-ce12-4cd0-a996-567848bdbaeas")
    }
}