import Alchemy

struct 8803AF79-01BB-4644-B43C-53CA66B3A095: Migration {
    func up(schema: Schema) {
        schema.create(table: "users") {
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
        schema.drop(table: "users")
    }
}