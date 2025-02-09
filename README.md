[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

# ds-supabase

**ds-supabase** is a FiveM resource that provides a Supabase client with a JavaScript-like API for interacting with your Supabase database via its REST API. It offers an asynchronous, promise-based query builder with a rich set of filtering, ordering, and modifier methods, as well as support for calling Postgres functions (RPC).

## Features

- **Asynchronous Execution**: Supports both `await()` and `callback()` methods for handling queries.
- **Chainable Query Builder**: Enables easy filtering, ordering, limiting, and more.
- **Supabase RPC Support**: Allows calling Postgres functions directly from FiveM.
- **Lightweight & Efficient**: Designed to be performant and easy to integrate into existing projects.

---

## Installation

1. **Download or Clone the Repository**
   ```sh
   git clone https://github.com/yourgithubusername/ds-supabase.git
   ```
2. **Move to Your FiveM Resources Folder**
   ```sh
   mv ds-supabase /path/to/your/fivem/resources/
   ```
3. **Add to Your `server.cfg`**
   ```cfg
   ensure ds-supabase
   ```
4. **Restart Your Server**

---

## Getting Started

### Creating a Client

```lua
local supabase = exports["ds-supabase"].createClient("https://your-project.supabase.co", "your-supabase-key")
```

### Querying Data

#### Using `await()`
```lua
local data, error = supabase:from("players"):select():await()
if error then
    print("Fetch error:", error)
else
    print("Fetched players:", data)
end
```

#### Using `callback()`
```lua
supabase:from("players"):select():callback(function(data, error)
    if error then
        print("Callback error:", error)
    else
        print("Callback fetched players:", data)
    end
end)
```

### Inserting Data
```lua
local data, error = supabase:from("players"):insert({ name = "Alice", score = 100 }):await()
```

### Updating Data
```lua
local data, error = supabase:from("players"):eq("id", 1):update({ score = 150 }):await()
```

### Deleting Data
```lua
local data, error = supabase:from("players"):eq("id", 1):delete():await()
```

### RPC Calls
```lua
local rpcData, rpcError = supabase:rpc("increment", { amount = 1 }):await()
```

---

## API Reference

### SupabaseClient

- **createClient(url, key)**: Creates a new Supabase client.
- **from(tableName)**: Returns a `QueryBuilder` instance for querying.
- **rpc(functionName, params, options)**: Calls a Postgres function via RPC.

### QueryBuilder Methods

#### Filter Methods
- `eq(column, value)`: Where column equals value.
- `neq(column, value)`: Where column is not equal to value.
- `gt(column, value)`, `gte(column, value)`, `lt(column, value)`, `lte(column, value)`: Numeric comparisons.
- `like(column, pattern)`, `ilike(column, pattern)`: Pattern matching.
- `in(column, values)`: Matches an array of values.

#### Modifier Methods
- `order(column, options)`: Order results by column.
- `limit(n)`: Limit number of rows.
- `range(from, to)`: Query a specific range.
- `single()`, `maybeSingle()`: Return one row or possibly one row.
- `csv()`: Return as CSV.

#### Terminal Methods
- `select(columns)`, `insert(data)`, `update(data)`, `upsert(data, options)`, `delete()`.

#### Async Handling
- `await()`: Returns `[data, error]`.
- `callback(fn)`: Registers a callback for handling the result.

### RPCBuilder Methods
- `execute()`: Executes an RPC function.
- `await()`: Awaits the RPC call.
- `callback(fn)`: Executes RPC with a callback.

---

## License
This project is licensed under the MIT License.

## Contributing
Contributions are welcome! Open an issue or submit a pull request on GitHub.

## Support
For questions or support, please open an issue on [GitHub](https://github.com/yourgithubusername/ds-supabase/issues).

