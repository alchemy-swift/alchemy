import Alchemy

struct Create7B110B0F-C75D-4FE8-A00F-AFB24CCDF2E5s: Migration {
    func up(schema: Schema) {
        schema.create(table: "7_b110b0f-c75d-4fe8-a00f-afb24ccdf2e5s") {
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
        schema.drop(table: "7_b110b0f-c75d-4fe8-a00f-afb24ccdf2e5s")
    }
}