[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)

# Supabase Wrapper for FiveM

A robust FiveM resource that provides a complete wrapper for Supabase's REST API. This resource exposes CRUD operations with enhanced error handling, allowing your other server resources to easily interact with a Supabase database.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Exported Functions](#exported-functions)
  - [InsertData](#insertdata)
  - [QueryData](#querydata)
  - [UpdateData](#updatedata)
  - [DeleteData](#deletedata)
- [Error Handling](#error-handling)
- [Debug Command](#debug-command)
- [License](#license)
- [Contributing](#contributing)
- [Support](#support)

## Overview

This resource is designed to simplify interacting with a Supabase database from your FiveM server. It provides functions to insert, query, update, and delete records in your Supabase tables via REST API calls—all from within your FiveM server. Each function includes enhanced error handling, ensuring that you receive detailed feedback in case of failure.

## Features

- **CRUD Operations:**  
  - **InsertData:** Insert new records into a table.
  - **QueryData:** Retrieve data from a table with optional query parameters.
  - **UpdateData:** Update existing records in a table.
  - **DeleteData:** Delete records from a table.
- **Enhanced Error Handling:**  
  Each API call validates the response, decodes error messages (if any), and passes meaningful error information back to your callback.
- **Exports for Easy Integration:**  
  All functions are exported, so they can be called directly from other resources using `exports.supabase_wrapper:<FunctionName>(...)`.
- **Debug Command:**  
  Use the `/supatest` command to quickly test connectivity and query a specified table.

## Installation

1. **Download/Clone the Resource:**

   Place the `supabase_wrapper` folder inside your server's `resources` directory with the following structure:

   ```
   resources/
   └── supabase_wrapper/
       ├── fxmanifest.lua
       └── server.lua
   ```

2. **Update Your Server Configuration:**

   In your `server.cfg`, add the following line to ensure the resource starts:

   ```cfg
   ensure supabase_wrapper
   ```

## Configuration

This resource requires two configuration variables (convars) to be set in your `server.cfg`:

- **supabase_url:** The URL of your Supabase project.
- **supabase_key:** Your Supabase API key.

Example configuration:

```cfg
set supabase_url "https://your-project.supabase.co"
set supabase_key "your-supabase-key"
```

Make sure these values are set **before** starting the resource.

## Exported Functions

The following functions are exported by the resource and can be called from other server scripts.

### InsertData

**Description:**  
Inserts a new record into the specified table.

**Usage:**

```lua
exports.supabase_wrapper:InsertData(tableName, data, callback)
```

- `tableName` (string): The name of the Supabase table.
- `data` (table): A Lua table representing the record to insert.
- `callback` (function): A callback function that receives `(statusCode, responseText, responseHeaders)`.

**Example:**

```lua
exports.supabase_wrapper:InsertData("players", { name = "John Doe", score = 100 }, function(statusCode, responseText, responseHeaders)
    if statusCode == 200 or statusCode == 201 then
        print("Insert successful!")
    else
        print("Insert failed with error: " .. responseText)
    end
end)
```

### QueryData

**Description:**  
Queries data from the specified table. Optionally, you can pass URL query parameters.

**Usage:**

```lua
exports.supabase_wrapper:QueryData(tableName, queryParams, callback)
```

- `tableName` (string): The name of the table.
- `queryParams` (string, optional): URL query parameters (e.g., `"select=*&id=eq.1"`).
- `callback` (function): A callback function that receives `(statusCode, responseText, responseHeaders)`.

**Example:**

```lua
exports.supabase_wrapper:QueryData("players", "select=*&score=gt.100", function(statusCode, responseText, responseHeaders)
    if statusCode == 200 then
        local data = json.decode(responseText)
        print("Query returned " .. #data .. " record(s).")
    else
        print("Query failed with error: " .. responseText)
    end
end)
```

### UpdateData

**Description:**  
Updates an existing record in the specified table. This uses the HTTP PATCH method for partial updates.

**Usage:**

```lua
exports.supabase_wrapper:UpdateData(tableName, data, queryParams, callback)
```

- `tableName` (string): The name of the table.
- `data` (table): A Lua table representing the fields to update.
- `queryParams` (string, optional): URL query parameters to filter which records to update.
- `callback` (function): A callback function that receives `(statusCode, responseText, responseHeaders)`.

**Example:**

```lua
exports.supabase_wrapper:UpdateData("players", { score = 150 }, "id=eq.1", function(statusCode, responseText, responseHeaders)
    if statusCode == 204 then
        print("Update successful!")
    else
        print("Update failed with error: " .. responseText)
    end
end)
```

### DeleteData

**Description:**  
Deletes records from the specified table.

**Usage:**

```lua
exports.supabase_wrapper:DeleteData(tableName, queryParams, callback)
```

- `tableName` (string): The name of the table.
- `queryParams` (string, optional): URL query parameters to filter which records to delete.
- `callback` (function): A callback function that receives `(statusCode, responseText, responseHeaders)`.

**Example:**

```lua
exports.supabase_wrapper:DeleteData("players", "id=eq.1", function(statusCode, responseText, responseHeaders)
    if statusCode == 204 then
        print("Delete successful!")
    else
        print("Delete failed with error: " .. responseText)
    end
end)
```

## Debug Command

For testing purposes, a debug command is available:

```
/supatest <tableName> [queryParams]
```

- **Usage Example:**

  ```
  /supatest players "select=*"
  ```

This command queries the specified table and prints the results (or error messages) to the server console.

## License

Include your license information here. For example:

```
MIT License
```

## Contributing

Contributions are welcome! Please submit pull requests or open an issue if you have suggestions, bug reports, or feature requests.

## Support

If you need support or have questions, please open an issue on the repository or contact [Your Contact Information].
