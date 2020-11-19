# Migrations

Migrations are a key part of development experience. They apply or rollback changes to the schema of your database and are typically used when adding new models or removing old models.

## Creating a migration
You can create a new migration using the CLI.

```bash
alchemy new migration
```

This will create a new migration file in the `Migrations/` directory named with the current timestamp.

The migration can then be implemented by 