-- server.lua
-- Supabase JS-like Client for FiveM (Asynchronous Only with Promise and Callback Support)
-- Exported as "ds-supabase"
--
-- Example usage:
--   local supabase = exports["ds-supabase"].createClient("https://your-project.supabase.co", "your-supabase-key")
--
--   -- Using await method:
--   local data, error = supabase:from("players"):select():await()
--
--   -- Using callback method:
--   supabase:from("players"):select():callback(function(data, error)
--       if error then
--           print("Error:", error)
--       else
--           print("Data:", data)
--       end
--   end)

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
        ["apikey"] = key,
        ["Authorization"] = "Bearer " .. key,
        ["Content-Type"] = "application/json"
    }
    return client
end

-- Returns a new query builder for a specific table.
function SupabaseClient:from(tableName)
    return QueryBuilder:new(self, tableName)
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
    self.filters = {}          -- Holds filter strings (e.g., "column=eq.value")
    self.select_columns = "*"  -- Default: select all columns
    self.method = nil          -- HTTP method ("GET", "POST", etc.)
    self.data = nil            -- Payload for POST/PATCH
    self.operation = nil       -- Operation type ("select", "insert", etc.)
    self.singleRow = false     -- Flag to return a single row (if desired)
    self.upsert = false        -- Flag for upsert operation
    self.on_conflict = nil     -- Optional conflict target for upsert
    return self
end

-- Standard filter methods.
function QueryBuilder:eq(column, value)
    table.insert(self.filters, column .. "=eq." .. tostring(value))
    return self
end

function QueryBuilder:neq(column, value)
    table.insert(self.filters, column .. "=neq." .. tostring(value))
    return self
end

function QueryBuilder:gt(column, value)
    table.insert(self.filters, column .. "=gt." .. tostring(value))
    return self
end

function QueryBuilder:gte(column, value)
    table.insert(self.filters, column .. "=gte." .. tostring(value))
    return self
end

function QueryBuilder:lt(column, value)
    table.insert(self.filters, column .. "=lt." .. tostring(value))
    return self
end

function QueryBuilder:lte(column, value)
    table.insert(self.filters, column .. "=lte." .. tostring(value))
    return self
end

-- Pattern matching.
function QueryBuilder:like(column, value)
    table.insert(self.filters, column .. "=like." .. tostring(value))
    return self
end

function QueryBuilder:ilike(column, value)
    table.insert(self.filters, column .. "=ilike." .. tostring(value))
    return self
end

-- "Is" operator.
function QueryBuilder:is(column, value)
    table.insert(self.filters, column .. "=is." .. tostring(value))
    return self
end

-- Array matching: Column is in an array.
-- "in" is reserved in Lua, so we use the table index notation.
function QueryBuilder["in"](self, column, value)
    local formatted = ""
    if type(value) == "table" then
        formatted = "(" .. table.concat(value, ",") .. ")"
    else
        formatted = tostring(value)
    end
    table.insert(self.filters, column .. "=in." .. formatted)
    return self
end

-- Containment operators.
function QueryBuilder:contains(column, value)
    table.insert(self.filters, column .. "=contains." .. tostring(value))
    return self
end

function QueryBuilder:containedBy(column, value)
    table.insert(self.filters, column .. "=containedBy." .. tostring(value))
    return self
end

-- Range operators.
function QueryBuilder:rangeGt(column, value)
    table.insert(self.filters, column .. "=rangeGt." .. tostring(value))
    return self
end

function QueryBuilder:rangeGte(column, value)
    table.insert(self.filters, column .. "=rangeGte." .. tostring(value))
    return self
end

function QueryBuilder:rangeLt(column, value)
    table.insert(self.filters, column .. "=rangeLt." .. tostring(value))
    return self
end

function QueryBuilder:rangeLte(column, value)
    table.insert(self.filters, column .. "=rangeLte." .. tostring(value))
    return self
end

function QueryBuilder:rangeAdjacent(column, value)
    table.insert(self.filters, column .. "=rangeAdjacent." .. tostring(value))
    return self
end

-- Overlap.
function QueryBuilder:overlaps(column, value)
    table.insert(self.filters, column .. "=overlaps." .. tostring(value))
    return self
end

-- Full-text search.
function QueryBuilder:textSearch(column, value)
    table.insert(self.filters, column .. "=textSearch." .. tostring(value))
    return self
end

-- Match: adds equality filters for each key in a table.
function QueryBuilder:match(object)
    for k, v in pairs(object) do
        self:eq(k, v)
    end
    return self
end

-- Negation: "not" is reserved, so we use table indexing.
function QueryBuilder["not"](self, column, value)
    table.insert(self.filters, column .. "=not.eq." .. tostring(value))
    return self
end

-- Logical OR: "or" is reserved; use table indexing.
-- Accepts a filter string such as "column.eq.value,column2.gt.value".
function QueryBuilder["or"](self, filterString)
    table.insert(self.filters, "or=(" .. tostring(filterString) .. ")")
    return self
end

-- Generic filter method.
function QueryBuilder:filter(column, operator, value)
    table.insert(self.filters, column .. "=" .. operator .. "." .. tostring(value))
    return self
end

-- Chainable method to indicate that only a single row should be returned.
function QueryBuilder:single()
    self.singleRow = true
    return self
end

-- Terminal methods (always asynchronous; they return a promise).

-- For select, if upsert was previously called, we use POST.
function QueryBuilder:select(columns)
    if columns then
        self.select_columns = columns
    end
    if self.upsert then
        self.method = "POST"
        self.operation = "upsert"
    else
        self.method = "GET"
        self.operation = "select"
    end
    return self:execute()
end

function QueryBuilder:insert(data)
    self.method = "POST"
    self.operation = "insert"
    self.data = data
    return self:execute()
end

function QueryBuilder:update(data)
    self.method = "PATCH"
    self.operation = "update"
    self.data = data
    return self:execute()
end

-- Upsert accepts an optional second parameter for conflict handling.
function QueryBuilder:upsert(data, options)
    self.method = "POST"
    self.operation = "upsert"
    self.data = data
    self.upsert = true
    if options and options.onConflict then
        self.on_conflict = options.onConflict
    end
    return self:execute()
end

function QueryBuilder:delete()
    self.method = "DELETE"
    self.operation = "delete"
    return self:execute()
end

-- Chainable method to use a callback.
-- The provided callback function is invoked with two parameters: data and error.
function QueryBuilder:callback(cb)
    local p = self:execute()
    p:next(function(result)
        cb(result.data, result.error)
        return result
    end)
    return p
end

-- Chainable method to automatically await the promise.
-- Returns data, error.
function QueryBuilder:await()
    local result = promise.await(self:execute())
    return result.data, result.error
end

-- Builds the request URL with query parameters.
function QueryBuilder:buildUrl()
    local url = self.client.url .. "/rest/v1/" .. self.table
    local params = {}

    if self.operation == "select" or self.operation == "upsert" then
        table.insert(params, "select=" .. self.select_columns)
    end

    if self.upsert then
        table.insert(params, "upsert=true")
    end

    if self.on_conflict then
        table.insert(params, "on_conflict=" .. self.on_conflict)
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

-- Executes the HTTP request and returns a promise.
-- The promise resolves to a table: { data = <decoded JSON or nil>, error = <error message or nil> }.
function QueryBuilder:execute()
    local p = promise.new()
    local url = self:buildUrl()
    local payload = ""
    if self.method == "POST" or self.method == "PATCH" then
        payload = json.encode(self.data)
    end

    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        local result = { data = nil, error = nil }
        if statusCode == 0 then
            result.error = "HTTP request failed (no response received)"
        else
            local successDecode, decoded = pcall(json.decode, responseText)
            if successDecode then
                if self.singleRow then
                    result.data = decoded[1] or nil
                else
                    result.data = decoded
                end
            else
                result.error = "Failed to decode JSON"
            end
        end
        p:resolve(result)
    end, self.method, payload, self.client.headers)

    return p
end

----------------------------------------
-- MODULE EXPORT: SUPABASE
----------------------------------------
local Supabase = {}

-- Creates and returns a new Supabase client.
function Supabase.createClient(url, key)
    return SupabaseClient:create(url, key)
end

exports("createClient", Supabase.createClient)
return Supabase
