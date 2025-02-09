--[[
  Supabase JS-like Client for FiveM
  ----------------------------------
  This resource provides a Supabase client with a chainable API similar to supabase-js.
  
  Usage Example:
  
    -- In another server script:
    local supabase = exports.supabase_wrapper:createClient(
        GetConvar('supabase_url', 'https://your-project.supabase.co'),
        GetConvar('supabase_key', 'your-supabase-key')
    )
    
    supabase:from("players")
        :eq("id", 1)
        :select("*", function(status, response, headers)
            if status == 200 then
                local data = json.decode(response)
                print("Query succeeded! Data:", data)
            else
                print("Query failed with error: " .. response)
            end
        end)
        
  The available chainable methods include:
    - from(tableName) — Returns a query builder for the given table.
    - eq(column, value) — Adds an equality filter.
    - neq(column, value) — Adds a "not equal" filter.
    - gt(column, value)  — Greater than filter.
    - gte(column, value) — Greater than or equal filter.
    - lt(column, value)  — Less than filter.
    - lte(column, value) — Less than or equal filter.
  
  Terminal methods to execute the query:
    - select(columns, callback) — Performs a GET request. `columns` defaults to "*".
    - insert(data, callback)    — Performs a POST request.
    - update(data, callback)    — Performs a PATCH request.
    - delete(callback)          — Performs a DELETE request.
  
  All terminal methods execute the HTTP request immediately and pass
  `(statusCode, responseText, responseHeaders)` to the provided callback.
--]]

----------------------------------------
-- SUPABASE CLIENT (SupabaseClient)
----------------------------------------

local SupabaseClient = {}
SupabaseClient.__index = SupabaseClient

-- Creates a new Supabase client instance.
function SupabaseClient:create(url, key)
    local client = setmetatable({}, SupabaseClient)
    client.url = url
    client.key = key
    client.headers = {
        ["apikey"]        = key,
        ["Authorization"] = "Bearer " .. key,
        ["Content-Type"]  = "application/json"
    }
    return client
end

-- Returns a query builder for a specific table.
function SupabaseClient:from(tableName)
    return QueryBuilder:new(self, tableName)
end

-- Standardized error handling.
function SupabaseClient:handleResponse(expectedCodes, statusCode, responseText, responseHeaders, callback)
    statusCode = tonumber(statusCode) or 0
    if statusCode == 0 then
        if callback then callback(statusCode, "HTTP request failed (no response received)", responseHeaders) end
        return
    end

    local isSuccess = false
    for _, code in ipairs(expectedCodes) do
        if statusCode == code then
            isSuccess = true
            break
        end
    end

    if not isSuccess then
        local errorMsg = responseText or "Unknown error occurred"
        local successDecode, decoded = pcall(json.decode, responseText)
        if successDecode and type(decoded) == "table" then
            if decoded.error then
                errorMsg = decoded.error
            elseif decoded.message then
                errorMsg = decoded.message
            end
        end
        if callback then callback(statusCode, errorMsg, responseHeaders) end
    else
        if callback then callback(statusCode, responseText, responseHeaders) end
    end
end

----------------------------------------
-- QUERY BUILDER (QueryBuilder)
----------------------------------------

local QueryBuilder = {}
QueryBuilder.__index = QueryBuilder

-- Initializes a new query builder for a given client and table.
function QueryBuilder:new(client, tableName)
    local self = setmetatable({}, QueryBuilder)
    self.client = client
    self.table = tableName
    self.filters = {}        -- Holds filter strings like "column=eq.value"
    self.select_columns = "*" -- Default select is all columns
    self.method = nil        -- HTTP method ("GET", "POST", etc.)
    self.data = nil          -- Payload for POST/PATCH
    self.operation = nil     -- Operation type ("select", "insert", etc.)
    self.callback = nil      -- User-provided callback function
    return self
end

-- Adds an equality filter.
function QueryBuilder:eq(column, value)
    table.insert(self.filters, column .. "=eq." .. tostring(value))
    return self
end

-- Adds a not-equal filter.
function QueryBuilder:neq(column, value)
    table.insert(self.filters, column .. "=neq." .. tostring(value))
    return self
end

-- Adds a greater-than filter.
function QueryBuilder:gt(column, value)
    table.insert(self.filters, column .. "=gt." .. tostring(value))
    return self
end

-- Adds a greater-than-or-equal filter.
function QueryBuilder:gte(column, value)
    table.insert(self.filters, column .. "=gte." .. tostring(value))
    return self
end

-- Adds a less-than filter.
function QueryBuilder:lt(column, value)
    table.insert(self.filters, column .. "=lt." .. tostring(value))
    return self
end

-- Adds a less-than-or-equal filter.
function QueryBuilder:lte(column, value)
    table.insert(self.filters, column .. "=lte." .. tostring(value))
    return self
end

-- Terminal method: Executes a SELECT request.
-- @param columns (string) Optional; defaults to "*" if nil.
-- @param callback (function) Called with (statusCode, responseText, responseHeaders)
function QueryBuilder:select(columns, callback)
    self.method = "GET"
    self.operation = "select"
    if columns then
        self.select_columns = columns
    end
    self.callback = callback
    self:execute()
    return self
end

-- Terminal method: Executes an INSERT request.
-- @param data (table) The record(s) to insert.
-- @param callback (function) Called with (statusCode, responseText, responseHeaders)
function QueryBuilder:insert(data, callback)
    self.method = "POST"
    self.operation = "insert"
    self.data = data
    self.callback = callback
    self:execute()
    return self
end

-- Terminal method: Executes an UPDATE request.
-- @param data (table) The record fields to update.
-- @param callback (function) Called with (statusCode, responseText, responseHeaders)
function QueryBuilder:update(data, callback)
    self.method = "PATCH"
    self.operation = "update"
    self.data = data
    self.callback = callback
    self:execute()
    return self
end

-- Terminal method: Executes a DELETE request.
-- @param callback (function) Called with (statusCode, responseText, responseHeaders)
function QueryBuilder:delete(callback)
    self.method = "DELETE"
    self.operation = "delete"
    self.callback = callback
    self:execute()
    return self
end

-- Constructs the request URL with query parameters.
function QueryBuilder:buildUrl()
    local url = self.client.url .. "/rest/v1/" .. self.table
    local params = {}

    if self.operation == "select" then
        table.insert(params, "select=" .. self.select_columns)
    end

    if #self.filters > 0 then
        for _, filter in ipairs(self.filters) do
            table.insert(params, filter)
        end
    end

    if #params > 0 then
        url = url .. "?" .. table.concat(params, "&")
    end

    return url
end

-- Determines the expected HTTP status codes based on the HTTP method.
function QueryBuilder:expectedCodes()
    if self.method == "GET" then
        return {200}
    elseif self.method == "POST" then
        return {200, 201}
    elseif self.method == "PATCH" then
        return {204}
    elseif self.method == "DELETE" then
        return {204}
    else
        return {200}
    end
end

-- Executes the HTTP request using the built URL and method.
function QueryBuilder:execute()
    local url = self:buildUrl()
    local payload = ""

    if self.method == "POST" or self.method == "PATCH" then
        payload = json.encode(self.data)
    end

    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        self.client:handleResponse(self:expectedCodes(), statusCode, responseText, responseHeaders, self.callback)
    end, self.method, payload, self.client.headers)
end

----------------------------------------
-- MODULE EXPORT: SUPABASE
----------------------------------------

local Supabase = {}

-- Creates and returns a new Supabase client.
function Supabase.createClient(url, key)
    return SupabaseClient:create(url, key)
end

-- Export the createClient function so that other resources can call it:
-- Usage example: exports.supabase_wrapper:createClient(...)
exports('createClient', Supabase.createClient)

-- Optionally, return the module for direct requiring.
return Supabase
