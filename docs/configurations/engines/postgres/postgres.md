# Postgres

PostgreSQL is a powerful, open-source relational database that works great with Vulcan. It's perfect for smaller projects, development environments, or when you want full control over your database infrastructure.

## Local/Built-in Scheduler
**Engine Adapter Type**: `postgres`

### Connection options

Here are all the connection parameters you can use when setting up a PostgreSQL gateway:

| Option             | Description                                                                     | Type   | Required |
|--------------------|---------------------------------------------------------------------------------|:------:|:--------:|
| `type`             | Engine type name - must be `postgres`                                           | string | Y        |
| `host`             | The hostname of the Postgres server                                             | string | Y        |
| `user`             | The username to use for authentication with the Postgres server                 | string | Y        |
| `password`         | The password to use for authentication with the Postgres server                 | string | Y        |
| `port`             | The port number of the Postgres server                                          | int    | Y        |
| `database`         | The name of the database instance to connect to                                 | string | Y        |
| `keepalives_idle`  | The number of seconds between each keepalive packet sent to the server.         | int    | N        |
| `connect_timeout`  | The number of seconds to wait for the connection to the server. (Default: `10`) | int    | N        |
| `role`             | The role to use for authentication with the Postgres server                     | string | N        |
| `sslmode`          | The security of the connection to the Postgres server                           | string | N        |
| `application_name` | The name of the application to use for the connection                           | string | N        |
