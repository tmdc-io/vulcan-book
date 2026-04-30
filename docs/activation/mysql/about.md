## Connecting via MySQL

There are multiple interface to connect to your semantic layer through MySQL. Choose the one that fits your workflow.

---

### Option 1 - MySQL Shell

*If you don't have MySQL Shell installed, download it for your OS from the official documentation:*

```
https://dev.mysql.com/doc/mysql-shell/8.4/en/mysql-shell-install.html
```

---

Run the following command to connect, replacing the placeholders with your tenant details:

```bash
mysql -h tcp.{instance_name} -P 3306 -u {username} -p'{apikey}' --enable-cleartext-plugin {tenant_name}.{dataproduct_name}
```

Once connected, you can explore your semantic layer using standard MySQL commands:

```sql
-- List all available tables
SHOW TABLES;

-- View the structure of a table
DESCRIBE table_name;

-- List columns from a specific table
SHOW COLUMNS FROM table_name;
```

---

### Option 2 - DBeaver or other IDEs

DBeaver and most SQL IDEs support MySQL connections. Use the following connection details in your IDE's new connection dialog:

| Field | Value |
|---|---|
| Host | `tcp.{instance_name}` |
| Port | `3306` |
| Username | `{username}` |
| Password | `{apikey}` |
| Database | `{tenant_name}.{dataproduct_name}` |

> **Note** - Make sure to enable **cleartext authentication** in your IDE's advanced or SSL settings. This is required for the connection to succeed.