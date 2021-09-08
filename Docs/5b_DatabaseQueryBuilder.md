# Database: Query Builder

- [Running Database Queries](#running-database-queries)
  * [Starting a query chain](#starting-a-query-chain)
  * [Get all rows](#get-all-rows)
  * [Get a single row](#get-a-single-row)
- [Select](#select)
  * [Picking columns to return](#picking-columns-to-return)
- [Joins](#joins)
- [Where Clauses](#where-clauses)
  * [Basic Where Clauses](#basic-where-clauses)
  * [Or Where Clauses](#or-where-clauses)
  * [Grouping Where Clauses](#grouping-where-clauses)
  * [Additional Where Clauses](#additional-where-clauses)
    + [Where Null](#where-null)
    + [Where In](#where-in)
- [Ordering, Grouping, Paging](#ordering-grouping-paging)
  * [Grouping](#grouping)
  * [Ordering](#ordering)
  * [Paging, Limits and Offsets](#paging-limits-and-offsets)
- [Inserting](#inserting)
- [Updating](#updating)
- [Deleting](#deleting)
- [Counting](#counting)

Alchemy offers first class support for building and running database queries through a chaining query builder. It can be used for the majority of database operations, otherwise you can always run pure SQL as well. The syntax is heavily inspired by Knex and Laravel.

## Running Database Queries

### Starting a query chain
To start fetching records, you can begin a chain a number of different ways. Each will start a query builder chain that you can then build out.

```swift
Query.from("users")... // Start a query on table `users` using the default database.
// or 
Model.query()... // Start a query and automatically sets the table from the model.
// or
database.query().from("users") // Start a query using a database variable on table `users`.
```

### Get all rows
```swift
Query.from("users")
  .get()
```

### Get a single row

If you are only wanting to select a single row from the database table, you have a few different options. 

To select the first row only from a query, use the `first` method.
```swift
Query.from("users")
  .where("name", "Steve")
  .first()
```

If you want to get a single record based on a given column, you can use the `find` method. This will return the first record matching the criteria.
```swift
Query.from("users")
  .find()
```

## Select

### Picking columns to return

Sometimes you may want to select just a subset of columns to return. While the `find` and `get` methods can take a list of columns to limit down to, you can always explicitly call `select`.

```swift 
Query.from("users")
  .select(["first_name", "last_name"])
  .get()
```

## Joins

You can easily join data from separate tables using the query builder. The `join` method needs the table you are joining, and a clause to match up the data. If for example you are wanting to join all of a users order data, you could do the following:

```swift
Query.from("users")
  .join(table: "orders", first: "users.id", op: .equals, second: "orders.user_id")
  .get()
```

There are helper methods available for `leftJoin`, `rightJoin` and `crossJoin` that you can use that take the same basic parameters.

## Where Clauses

### Basic Where Clauses

If you are wanting to filter down your results this can be done by using the `where` method. You can add as many where clauses to your query to continually filter down as far as needed. The simplest usage is to construct a `WhereValue` clause using some of the common operators. To do this, you would pass a column, the operator and then the value. For example if you wanted to get all users over 20 years old, you could do so as follows:

```swift
Query.from("users")
  .where("age" > 20)
  .get()
```

The following operators are valid when constructing a `WhereValue` in this way: `==`, `!=`, `<`, `>`, `<=`, `>=`, `~=`.

Alternatively you can manually create a `WhereValue` clause manually:

```swift
Query.from("users")
  .where(WhereValue(key: "age", op: .equals, value: 10))
  .get()
```

### Or Where Clauses

By default chaining where clauses will be joined together using the `and` operator. If you ever need to switch the operator to `or` you can do so by using the `orWhere` method.

```swift
Query.from("users")
  .where("age" > 20)
  .orWhere("age" < 50)
  .get()
```

### Grouping Where Clauses

If you need to group where clauses together, you can do so by using a closure. This will execute those clauses together within parenthesis to achieve your desired logical grouping.

```swift
Query.from("users")
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

The provided example would produce the following SQL:

```sql
select * from users where (age < 50 or first_name = 'Paul') and (age > 50 or first_name = 'Karen')
```

### Additional Where Clauses

There are some additional helper where methods available for common cases. All methods also have a corresponding `or` method as well.

#### Where Null

The `whereNull` method ensures that the given column is not null.

```swift
Query.from("users")
  .whereNull("last_name")
  .get()
```

#### Where In

The `where(key: String, in values [Parameter])` method lets you pass an array of values to match the column against.

```swift
Query.from("users")
  .where(key: "age", in: [10,20,30])
  .get()
```

## Ordering, Grouping, Paging

### Grouping

To group results together, you can use the `groupBy` method:

```swift
Query.from("users")
  .groupBy("age")
  .get()
```

If you need to filter the grouped by rows, you can use the `having` method which performs similar to a `where` clause.

```swift
Query.from("users")
  .groupBy("age")
  .having("age" > 100)
  .get()
```

### Ordering

You can sort results of a query by using the `orderBy` method. 

```swift
Query.from("users")
  .orderBy(column: "first_name", direction: .asc)
  .get()
```

If you need to sort by multiple columns, you can add `orderBy` as many times as needed. Sorting is based on call order.

```swift
Query.from("users")
  .orderBy(column: "first_name", direction: .asc)
  .orderBy(column: "last_name", direction: .desc)
  .get()
```

### Paging, Limits and Offsets

If all you are looking for is to break a query down into chunks for paging, the easiest way to accomplish that is to use the `forPage` method. It will automatically set the limits and offsets appropriate for a page size you define.

```swift
Query.from("users")
  .forPage(page: 1, perPage: 25)
  .get()
```

Otherwise, you can also define limits and offsets manually:
```swift
Query.from("users")
  .offset(50)
  .limit(10)
  .get()
```

## Inserting

You can insert records using the query builder as well. To do so, start a chain with only a table name, and then pass the record you wish to insert. You can additionally pass in an array of records to do a bulk insert.

```swift
Query.table("users")
  .insert([
    "first_name": "Steve",
    "last_name": "Jobs"
  ])
```

## Updating

Updating records is just as easy as inserting, however you also get the benefit of the rest of the query builder chain. Any where clauses that have been added are used to match which records you want to update. For example, if you wanted to update a single user based on an ID, you could do so as follows:

```swift
Query.table("users")
  .where("id" == 10)
  .update(values: [
    "first_name": "Ashley"
  ])
```

## Deleting

The `delete` method works similar to how `update` did. It uses the query builder chain to determine what records match, but then instead of updating them, it deletes them. If you wanted to delete all users whose name is Peter, you could do that as so:

```swift
Query.table("users")
  .where("name" == "Peter")
  .delete()
```

## Counting

To get the total number of records that match a query you can use the `count` method. 

```swift
Query.from("rentals")
  .where("num_beds" >= 1)
  .count(as: "rentals_count")
```

_Next page: [Database: Migrations](5c_DatabaseMigrations.md)_

_[Table of Contents](/Docs#docs)_
