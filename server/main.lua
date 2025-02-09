-- server.lua
-- Supabase JS-like Client for FiveM with Synchronous, Async (await), and Callback Support

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
    self.select_columns = "*"  -- Default select is all columns
    self.method = nil          -- HTTP method ("GET", "POST", etc.)
    self.data = nil            -- Payload for POST/PATCH
    self.operation = nil       -- Operation type ("select", "insert", etc.)
    self.singleRow = false     -- Flag for returning a single row
    self.upsert = false        -- Flag for upsert operation
    return self
end

-- Chainable filter methods
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

-- Chainable method to indicate that only a single row should be returned.
function QueryBuilder:single()
    self.singleRow = true
    return self
end

-- Chainable method to enable async execution.
-- This method automatically awaits the internal promise and returns data, error.
function QueryBuilder:await()
    local result = promise.await(self:execute(false)) -- false forces async mode
    return result.data, result.error
end

-- Chainable method to run asynchronously with a callback.
-- The provided callback function receives two parameters: result and error.
function QueryBuilder:callback(cb)
    local p = self:execute(false)  -- Always execute asynchronously in callback mode.
    p:next(function(result)
        cb(result.data, result.error)
        return result
    end)
    return p
end

-- Terminal methods (these do not execute the query immediately in async mode)
-- When not using :await() or :callback(), they run synchronously by default.

function QueryBuilder:select(columns)
    self.method = "GET"
    self.operation = "select"
    if columns then
        self.select_columns = columns
    end
    return self:execute(true) -- true for synchronous execution
end

function QueryBuilder:insert(data)
    self.method = "POST"
    self.operation = "insert"
    self.data = data
    return self:execute(true)
end

function QueryBuilder:update(data)
    self.method = "PATCH"
    self.operation = "update"
    self.data = data
    return self:execute(true)
end

function QueryBuilder:upsert(data)
    self.method = "POST"
    self.operation = "upsert"
    self.data = data
    self.upsert = true
    return self:execute(true)
end

function QueryBuilder:delete()
    self.method = "DELETE"
    self.operation = "delete"
    return self:execute(true)
end

-- Builds the request URL with query parameters.
function QueryBuilder:buildUrl()
    local url = self.client.url .. "/rest/v1/" .. self.table
    local params = {}

    if self.operation == "select" then
        table.insert(params, "select=" .. self.select_columns)
    end

    if self.upsert then
        table.insert(params, "upsert=true")
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

-- Executes the HTTP request.
-- If isSync is true, the function runs synchronously and returns data, error.
-- If isSync is false, the function returns a promise that will resolve to { data, error }.
function QueryBuilder:execute(isSync)
    local p = promise.new()
    local url = self:buildUrl()
    local payload = ""
    if self.method == "POST" or self.method == "PATCH" then
        payload = json.encode(self.data)
    end

    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        local result = { error = nil, data = nil }
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

    if isSync then
        local result = Citizen.Await(p)
        return result.data, result.error
    else
        return p
    end
end

----------------------------------------
-- MODULE EXPORT: SUPABASE
----------------------------------------

local Supabase = {}

-- Creates and returns a new Supabase client.
function Supabase.createClient(url, key)
    return SupabaseClient:create(url, key)
end

exports('createClient', Supabase.createClient)

return Supabase
