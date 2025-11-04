# Database Project

This project holds all the migrations for the database, this is to centeralize and manage the state of our database in one place easily.

## Commands to work with
> Ensure you have setup go migration.
>
> https://github.com/golang-migrate/migrate/tree/master/cmd/migrate

## Start a New Migration
1. `cd` into the migrations folder.
2. `migrate -path ./migrations create -ext sql -seq MIGRATION_NAME`

## Load the migrations
1. `cd` into the migrations folder.
2. `migrate -path ./migrations -database postgres://postgres:password@localhost:5432/gdmmorpg?sslmode=disable up`

## Reset the migrations
When getting stuck like with this error: `error: Dirty database version #####. Fix and force version.`
Do:
1. `migrate -path ./migrations -database postgres://postgres:password@localhost:5432/gdmmorpg?sslmode=disable drop -f`
then follow the `Load the migration` section.