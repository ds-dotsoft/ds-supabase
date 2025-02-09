-- server.lua
-- Supabase JS-like Client for FiveM (Asynchronous Only with Promise & Callback Support)
-- Exported as "ds-supabase"

----------------------------------------
-- SUPABASE CLIENT (SupabaseClient)
----------------------------------------

--- @class SupabaseClient
local SupabaseClient = {}
SupabaseClient.__index = SupabaseClient

--- Creates a new Supabase client instance.
-- @param url string The Supabase project URL.
-- @param key string The Supabase API key.
-- @return SupabaseClient A new Supabase client.
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

--- Returns a new QueryBuilder for the specified table.
-- @param tableName string The name of the table to query.
-- @return QueryBuilder A new query builder instance.
function SupabaseClient:from(tableName)
    return QueryBuilder:new(self, tableName)
end

--- RPC call to a Postgres function.
-- @param functionName string The Postgres function name.
-- @param params table Optional parameters to pass to the function.
-- @param options table Optional options.
-- @return RPCBuilder An RPC builder instance.
function SupabaseClient:rpc(functionName, params, options)
    return RPCBuilder:new(self, functionName, params, options)
end

----------------------------------------
-- QUERY BUILDER (QueryBuilder)
----------------------------------------

--- @class QueryBuilder
local QueryBuilder = {}
QueryBuilder.__index = QueryBuilder

--- Creates a new QueryBuilder instance.
-- @param client SupabaseClient The Supabase client.
-- @param tableName string The table name.
-- @return QueryBuilder A new query builder.
function QueryBuilder:new(client, tableName)
    local self = setmetatable({}, QueryBuilder)
    self.client = client
    self.table = tableName
    self.filters = {}           -- Array of filter strings.
    self.select_columns = "*"   -- Default: select all columns.
    self.method = nil           -- HTTP method ("GET", "POST", etc.).
    self.data = nil             -- Payload for POST/PATCH requests.
    self.operation = nil        -- Operation type ("select", "insert", etc.).
    self.singleRow = false      -- If true, return one row.
    self.maybeSingle = false    -- If true, return zero or one row.
    self.upsert = false         -- If true, perform an upsert.
    self.on_conflict = nil      -- Conflict target for upsert.
    self.order = nil            -- Order clause string.
    self.limit = nil            -- Limit clause.
    self.range = nil            -- Table with { from, to } for the "Range" header.
    self.abortSignal = nil      -- Function that returns true if the request should be aborted.
    self.csv = false            -- If true, return CSV output (raw string).
    return self
end

--- Filters where the column equals a value.
-- @param column string The column name.
-- @param value any The value to compare.
-- @return QueryBuilder self.
function QueryBuilder:eq(column, value)
    table.insert(self.filters, column .. "=eq." .. tostring(value))
    return self
end

--- Filters where the column is not equal to a value.
-- @param column string The column name.
-- @param value any The value to compare.
-- @return QueryBuilder self.
function QueryBuilder:neq(column, value)
    table.insert(self.filters, column .. "=neq." .. tostring(value))
    return self
end

--- Filters where the column is greater than a value.
-- @param column string The column name.
-- @param value any The value to compare.
-- @return QueryBuilder self.
function QueryBuilder:gt(column, value)
    table.insert(self.filters, column .. "=gt." .. tostring(value))
    return self
end

--- Filters where the column is greater than or equal to a value.
-- @param column string The column name.
-- @param value any The value to compare.
-- @return QueryBuilder self.
function QueryBuilder:gte(column, value)
    table.insert(self.filters, column .. "=gte." .. tostring(value))
    return self
end

--- Filters where the column is less than a value.
-- @param column string The column name.
-- @param value any The value to compare.
-- @return QueryBuilder self.
function QueryBuilder:lt(column, value)
    table.insert(self.filters, column .. "=lt." .. tostring(value))
    return self
end

--- Filters where the column is less than or equal to a value.
-- @param column string The column name.
-- @param value any The value to compare.
-- @return QueryBuilder self.
function QueryBuilder:lte(column, value)
    table.insert(self.filters, column .. "=lte." .. tostring(value))
    return self
end

--- Filters where the column matches a pattern.
-- @param column string The column name.
-- @param value string The pattern to match.
-- @return QueryBuilder self.
function QueryBuilder:like(column, value)
    table.insert(self.filters, column .. "=like." .. tostring(value))
    return self
end

--- Filters where the column matches a case-insensitive pattern.
-- @param column string The column name.
-- @param value string The pattern to match.
-- @return QueryBuilder self.
function QueryBuilder:ilike(column, value)
    table.insert(self.filters, column .. "=ilike." .. tostring(value))
    return self
end

--- Filters where the column is a value using the "is" operator.
-- @param column string The column name.
-- @param value any The value to compare.
-- @return QueryBuilder self.
function QueryBuilder:is(column, value)
    table.insert(self.filters, column .. "=is." .. tostring(value))
    return self
end

--- Filters where the column is in an array of values.
-- @param column string The column name.
-- @param value table|any An array of values or a single value.
-- @return QueryBuilder self.
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

--- Filters where the column contains every element in a value.
-- @param column string The column name.
-- @param value any The value to check.
-- @return QueryBuilder self.
function QueryBuilder:contains(column, value)
    table.insert(self.filters, column .. "=contains." .. tostring(value))
    return self
end

--- Filters where the column is contained by a value.
-- @param column string The column name.
-- @param value any The value to check.
-- @return QueryBuilder self.
function QueryBuilder:containedBy(column, value)
    table.insert(self.filters, column .. "=containedBy." .. tostring(value))
    return self
end

--- Filters where the column is greater than a range.
-- @param column string The column name.
-- @param value any The range value.
-- @return QueryBuilder self.
function QueryBuilder:rangeGt(column, value)
    table.insert(self.filters, column .. "=rangeGt." .. tostring(value))
    return self
end

--- Filters where the column is greater than or equal to a range.
-- @param column string The column name.
-- @param value any The range value.
-- @return QueryBuilder self.
function QueryBuilder:rangeGte(column, value)
    table.insert(self.filters, column .. "=rangeGte." .. tostring(value))
    return self
end

--- Filters where the column is less than a range.
-- @param column string The column name.
-- @param value any The range value.
-- @return QueryBuilder self.
function QueryBuilder:rangeLt(column, value)
    table.insert(self.filters, column .. "=rangeLt." .. tostring(value))
    return self
end

--- Filters where the column is less than or equal to a range.
-- @param column string The column name.
-- @param value any The range value.
-- @return QueryBuilder self.
function QueryBuilder:rangeLte(column, value)
    table.insert(self.filters, column .. "=rangeLte." .. tostring(value))
    return self
end

--- Filters where the column is mutually exclusive to a range.
-- @param column string The column name.
-- @param value any The range value.
-- @return QueryBuilder self.
function QueryBuilder:rangeAdjacent(column, value)
    table.insert(self.filters, column .. "=rangeAdjacent." .. tostring(value))
    return self
end

--- Filters where the column overlaps a value.
-- @param column string The column name.
-- @param value any The value to compare.
-- @return QueryBuilder self.
function QueryBuilder:overlaps(column, value)
    table.insert(self.filters, column .. "=overlaps." .. tostring(value))
    return self
end

--- Performs a full-text search on the column.
-- @param column string The column name.
-- @param value string The search query.
-- @return QueryBuilder self.
function QueryBuilder:textSearch(column, value)
    table.insert(self.filters, column .. "=textSearch." .. tostring(value))
    return self
end

--- Applies equality filters for multiple columns.
-- @param object table A table of key/value pairs.
-- @return QueryBuilder self.
function QueryBuilder:match(object)
    for k, v in pairs(object) do
        self:eq(k, v)
    end
    return self
end

--- Filters using negation.
-- @param column string The column name.
-- @param value any The value to negate.
-- @return QueryBuilder self.
function QueryBuilder["not"](self, column, value)
    table.insert(self.filters, column .. "=not.eq." .. tostring(value))
    return self
end

--- Filters using a logical OR.
-- @param filterString string A comma-separated filter string (e.g., "col1.eq.val,col2.gt.val").
-- @return QueryBuilder self.
function QueryBuilder["or"](self, filterString)
    table.insert(self.filters, "or=(" .. tostring(filterString) .. ")")
    return self
end

--- Applies a generic filter.
-- @param column string The column name.
-- @param operator string The operator.
-- @param value any The value to compare.
-- @return QueryBuilder self.
function QueryBuilder:filter(column, operator, value)
    table.insert(self.filters, column .. "=" .. operator .. "." .. tostring(value))
    return self
end

--- Orders the results by the specified column.
-- @param column string The column name.
-- @param options table Optional table with keys: ascending (boolean), nullsFirst (boolean), nullsLast (boolean).
-- @return QueryBuilder self.
function QueryBuilder:order(column, options)
    local asc = "asc"
    if options and options.ascending == false then
        asc = "desc"
    end
    local orderStr = column .. "." .. asc
    if options then
        if options.nullsFirst then
            orderStr = orderStr .. ".nullsfirst"
        elseif options.nullsLast then
            orderStr = orderStr .. ".nullslast"
        end
    end
    self.order = orderStr
    return self
end

--- Limits the number of rows returned.
-- @param n number The maximum number of rows.
-- @return QueryBuilder self.
function QueryBuilder:limit(n)
    self.limit = n
    return self
end

--- Limits the query to a specified range.
-- @param from number The starting index.
-- @param to number The ending index.
-- @return QueryBuilder self.
function QueryBuilder:range(from, to)
    self.range = { from = from, to = to }
    return self
end

--- Sets an abort signal for the query.
-- @param signal function A function that returns true if the operation should abort.
-- @return QueryBuilder self.
function QueryBuilder:abortSignal(signal)
    self.abortSignal = signal
    return self
end

--- Specifies that the query should return only one row.
-- @return QueryBuilder self.
function QueryBuilder:single()
    self.singleRow = true
    return self
end

--- Specifies that the query should return zero or one row.
-- @return QueryBuilder self.
function QueryBuilder:maybeSingle()
    self.maybeSingle = true
    return self
end

--- Specifies that the result should be returned as CSV.
-- @return QueryBuilder self.
function QueryBuilder:csv()
    self.csv = true
    return self
end

--- Terminal method: Executes a select query.
-- If upsert is set, uses POST; otherwise, uses GET.
-- @param columns string Optional list of columns to select.
-- @return Promise A promise that resolves to a table { data, error }.
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

--- Terminal method: Executes an insert query.
-- @param data table The data to insert.
-- @return Promise A promise that resolves to a table { data, error }.
function QueryBuilder:insert(data)
    self.method = "POST"
    self.operation = "insert"
    self.data = data
    return self:execute()
end

--- Terminal method: Executes an update query.
-- @param data table The data to update.
-- @return Promise A promise that resolves to a table { data, error }.
function QueryBuilder:update(data)
    self.method = "PATCH"
    self.operation = "update"
    self.data = data
    return self:execute()
end

--- Terminal method: Executes an upsert query.
-- Accepts an optional second parameter for conflict handling.
-- @param data table The data to upsert.
-- @param options table Optional table with key onConflict.
-- @return Promise A promise that resolves to a table { data, error }.
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

--- Terminal method: Executes a delete query.
-- @return Promise A promise that resolves to a table { data, error }.
function QueryBuilder:delete()
    self.method = "DELETE"
    self.operation = "delete"
    return self:execute()
end

--- Chainable method: Executes the query and invokes a callback.
-- @param cb function The callback function, which receives (data, error).
-- @return Promise The promise for the query.
function QueryBuilder:callback(cb)
    local p = self:execute()
    p:next(function(result)
        cb(result.data, result.error)
        return result
    end)
    return p
end

--- Chainable method: Awaits the promise and returns data and error.
-- @return any, string|nil Returns data and error.
function QueryBuilder:await()
    local result = promise.await(self:execute())
    return result.data, result.error
end

--- Builds the request URL with query parameters.
-- @return string The built URL.
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

    if self.order then
        table.insert(params, "order=" .. self.order)
    end

    if self.limit then
        table.insert(params, "limit=" .. tostring(self.limit))
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

--- Executes the HTTP request and returns a promise.
-- The promise resolves to a table: { data, error }.
-- @return Promise The promise for the HTTP request.
function QueryBuilder:execute()
    local p = promise.new()
    local url = self:buildUrl()
    local payload = ""
    if self.method == "POST" or self.method == "PATCH" then
        payload = json.encode(self.data)
    end

    -- Check for abort signal
    if self.abortSignal and type(self.abortSignal) == "function" and self.abortSignal() then
        p:resolve({ data = nil, error = "Aborted" })
        return p
    end

    -- Clone client's headers.
    local headers = {}
    for k, v in pairs(self.client.headers) do
        headers[k] = v
    end
    if self.range then
        headers["Range"] = string.format("%d-%d", self.range.from, self.range.to)
    end

    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        local result = { data = nil, error = nil }
        if statusCode == 0 then
            result.error = "HTTP request failed (no response received)"
        else
            if self.csv then
                result.data = responseText
            else
                local successDecode, decoded = pcall(json.decode, responseText)
                if successDecode then
                    if self.maybeSingle then
                        if type(decoded) == "table" then
                            if #decoded == 0 then
                                result.data = nil
                            elseif #decoded == 1 then
                                result.data = decoded[1]
                            else
                                result.error = "More than one row returned for maybeSingle"
                            end
                        else
                            result.data = decoded
                        end
                    elseif self.singleRow then
                        result.data = decoded[1] or nil
                    else
                        result.data = decoded
                    end
                else
                    result.error = "Failed to decode JSON"
                end
            end
        end
        p:resolve(result)
    end, self.method, payload, headers)

    return p
end

----------------------------------------
-- RPC BUILDER (RPCBuilder)
----------------------------------------

--- @class RPCBuilder
local RPCBuilder = {}
RPCBuilder.__index = RPCBuilder

--- Creates a new RPCBuilder instance.
-- @param client SupabaseClient The Supabase client.
-- @param functionName string The Postgres function name.
-- @param params table Optional parameters.
-- @param options table Optional options.
-- @return RPCBuilder A new RPC builder instance.
function RPCBuilder:new(client, functionName, params, options)
    local self = setmetatable({}, RPCBuilder)
    self.client = client
    self.functionName = functionName
    self.params = params or {}
    self.options = options or {}
    return self
end

--- Executes the RPC call and returns a promise.
-- @return Promise A promise that resolves to a table { data, error }.
function RPCBuilder:execute()
    local p = promise.new()
    local url = self.client.url .. "/rest/v1/rpc/" .. self.functionName
    local payload = json.encode(self.params)
    local headers = {}
    for k, v in pairs(self.client.headers) do
        headers[k] = v
    end
    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        local result = { data = nil, error = nil }
        if statusCode == 0 then
            result.error = "HTTP request failed (no response received)"
        else
            local successDecode, decoded = pcall(json.decode, responseText)
            if successDecode then
                result.data = decoded
            else
                result.error = "Failed to decode JSON"
            end
        end
        p:resolve(result)
    end, "POST", payload, headers)
    return p
end

--- Executes the RPC call and invokes the callback.
-- @param cb function The callback function receiving (data, error).
-- @return Promise The promise for the RPC call.
function RPCBuilder:callback(cb)
    local p = self:execute()
    p:next(function(result)
        cb(result.data, result.error)
        return result
    end)
    return p
end

--- Awaits the RPC call and returns data and error.
-- @return any, string|nil Returns data and error.
function RPCBuilder:await()
    local result = promise.await(self:execute())
    return result.data, result.error
end

----------------------------------------
-- MODULE EXPORT: SUPABASE
----------------------------------------

--- @module Supabase
local Supabase = {}

--- Creates a new Supabase client.
-- @param url string The Supabase project URL.
-- @param key string The Supabase API key.
-- @return SupabaseClient A new Supabase client.
function Supabase.createClient(url, key)
    return SupabaseClient:create(url, key)
end

exports("createClient", Supabase.createClient)
return Supabase
