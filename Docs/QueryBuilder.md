# Query Builder

Alchemy offers first class support for building and running database queries through a chaining query builder. It can be used for the majority of database operations, otherwise you can always run pure SQL as well. The syntax is heavily inspired by Knex and Laravel.


## Running Database Queries

### Starting a query chain
To start fetching records, you can begin a chain a number of different ways. Each will start a query builder chain that you can then build out.

```swift
DB.query()... // Start a query using the default DB
// or 
Model.query()... // Start a query and automatically sets the table from the model
// or
self.db.query() // Start a query using a database variable
```

### Get all rows
```swift
DB.query().from("users").get()
```

### Get a single row

If you are only wanting to select a single row from the database table, you have a few different options. 

To select the first row only from a query, use the `first` method.
```swift
DB.query()
	.from("users")
	.where("name", "Steve")
	.first()
```

If you want to get a single record based on a given column, you can use the `find` method. This will return the first record matching the criteria.
```swift
DB.query()
	.from("users")
	.find()
```


## Select

### Picking columns to return

Sometimes you may want to select just a subset of columns to return. While the `find` and `get` methods can take a list of columns to limit down to, you can always explicitly call `select`.

```swift 
DB.query()
	.from("users")
	.select(["first_name", "last_name"])
	.get()
```



## Joins

You can easily join data from separate tables using the query builder. The `join` method needs the table you are joining, and a clause to match up the data. If for example you are wanting to join all of a users order data, you could do the following:

```swift
DB.query()
	.from("users")
	.join(table: "orders", first: "users.id", op: .equals, second: "orders.user_id")
	.get()
```

There are helper methods available for `leftJoin`, `rightJoin` and `crossJoin` that you can use that take the same basic parameters.




## Where Clauses

### Basic Where Clauses

If you are wanting to filter down your results this can be done by using the `where` method. You can add as many where clauses to your query to continually filter down as far as needed. The simplest usage is to construct a `WhereValue` clause using some of the common operators. To do this, you would pass a column, the operator and then the value. For example if you wanted to get all users over 20 years old, you could do so as follows:

```swift
DB.query()
	.from("users")
	.where("age" > 20)
	.get()
```



The following operators are valid when constructing a `WhereValue` in this way: `==`, `!=`, `<`, `>`, `<=`, `>=`, `~=`.

Alternatively you can manually create a `WhereValue` clause manually:

```swift
DB.query()
	.from("users")
	.where(WhereValue(key: "age", op: .equals, value: 10))
	.get()
```



### Or Where Clauses

By default chaining where clauses will be joined together using the `and` operator. If you ever need to swift the operator to `or` you can do so by using the `orWhere` method.

```swift
DB.query()
	.from("users")
	.where("age" > 20)
	.orWhere("age" < 50)
	.get()
```



### Grouping Where Clauses

If you need to group where clauses together, you can do so by using a closure.

```swift
DB.query()
	.from("users")
	.where {
    $0.where("age" < 30)
    	.orWhere("first_name" == "Paul")
  }
	.orWhere {
    $0.where("age" > 50)
    	.orWhere("first_name" == "Karen")
  }
	.get()
```



### Additional Where Clauses

There are some additional helper where methods available for common cases. All methods also have a corresponding `or` method as well.

#### Where Null

The `whereNull` method ensures that the given column is not null.

```swift
DB.query()
	.from("users")
	.whereNull("last_name")
	.get()
```

#### Where In

The `where(key: String, in values [Parameter])` method lets you pass an array of values to match the column against.

```swift
DB.query()
	.from("users")
	.where(key: "age", in: [10,20,30])
	.get()
```


 

## Ordering, Grouping, Paging

### Grouping

To group results together, you can use the `groupBy` method:

```swift
DB.query()
	.from("users")
	.groupBy("age")
	.get()
```

If you need to filter the grouped by rows, you can use the `having` method which performs similar to a `where` clause.

```swift
DB.query()
	.from("users")
	.groupBy("age")
	.having("age" > 100)
	.get()
```



### Ordering

You can sort results of a query by using the `orderBy` method. 

```swift
DB.query()
    .from("users")
    .orderBy(column: "first_name", direction: .asc)
    .get()
```

If you need to sort by multiple columns, you can add `orderBy` as many times as needed. Sorting is based on call order.

```swift
DB.query()
    .from("users")
    .orderBy(column: "first_name", direction: .asc)
    .orderBy(column: "last_name", direction: .desc)
    .get()
```



### Paging, Limits & Offsets

If all you are looking for is to break a query down into chunks for paging, the easiest way to accomplish that is to use the `forPage` method. It will automatically set the limits and offsets appropriate for a page size you define.

```swift
DB.query()
    .from("users")
    .forPage(page: 1, perPage: 25)
    .get()
```

Otherwise, you can also define limits and offsets manually:
```swift
DB.query()
    .from("users")
    .offset(50)
    .limit(10)
    .get()
```



## Inserting

```swift
User.query().insert([
    [
        "first_name": "Steve",
        "last_name": "Jobs"
    ]
])
```



## Updating

```swift
User.query()
    .where("id" == 10)
    .update(values: ["some_json": DatabaseValue.json(nil)])
```

## Deleting

## Counting

```swift
Rental.query()
	.where("num_beds" >= 1)
	.count(as: "rentals_count")
```
