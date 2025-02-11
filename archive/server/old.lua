-- server.lua
-- Supabase JS-like Client for FiveM using ox_lib's class system.
-- Make sure to add "ox_lib" as a dependency in your fxmanifest.lua:
--    dependency 'ox_lib'

----------------------------------------
-- SUPABASE CLIENT (SupabaseClient)
----------------------------------------

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

---@class SupabaseClient : OxClass
---@field url string
---@field key string
---@field headers table
local SupabaseClient = lib.class('SupabaseClient')

---@class QueryBuilder : OxClass
---@field client SupabaseClient
---@field table string
---@field filters table
---@field select_columns string
---@field method string
---@field data any
---@field operation string
---@field singleRow boolean
---@field maybeSingle boolean
---@field upsert boolean
---@field on_conflict string
---@field order string
---@field limit number
---@field range table
---@field abortSignal function
---@field csv boolean
local QueryBuilder = lib.class('QueryBuilder')

---@class RPCBuilder : OxClass
---@field client SupabaseClient
---@field functionName string
---@field params table
---@field options table
local RPCBuilder = lib.class('RPCBuilder')

function SupabaseClient:constructor(url, key)
    self.url = url
    self.key = key
    self.headers = {
        apikey = key,
        Authorization = "Bearer " .. key,
        ["Content-Type"] = "application/json"
    }
end

function SupabaseClient:from(tableName)
    print("Called SupabaseClient:from")
    return QueryBuilder:new(self, tableName)
end

function SupabaseClient:rpc(functionName, params, options)
    return RPCBuilder:new(self, functionName, params, options)
end

----------------------------------------
-- QUERY BUILDER (QueryBuilder)
----------------------------------------

function QueryBuilder:constructor(client, tableName)
    self.client = client
    self.table = tableName
    self.filters = {}           -- Array of filter strings.
    self.select_columns = "*"   -- Default: select all columns.
    self.method = nil           -- HTTP method ("GET", "POST", etc.).
    self.data = nil             -- Payload for POST/PATCH requests.
    self.operation = nil        -- Operation type ("select", "insert", etc.).
    self.singleRow = false      -- If true, return one row.
    self._maybeSingle = false    -- If true, return zero or one row.
    self._upsert = false         -- If true, perform an upsert.
    self.on_conflict = nil      -- Conflict target for upsert.
    self._order = nil            -- Order clause string.
    self._limit = nil            -- Limit clause.
    self._range = nil            -- Table with { from, to } for the "Range" header.
    self._abortSignal = nil      -- Function that returns true if the request should be aborted.
    self._csv = false            -- If true, return CSV output (raw string).
    return self
end

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

function QueryBuilder:like(column, value)
    table.insert(self.filters, column .. "=like." .. tostring(value))
    return self
end

function QueryBuilder:ilike(column, value)
    table.insert(self.filters, column .. "=ilike." .. tostring(value))
    return self
end

function QueryBuilder:is(column, value)
    table.insert(self.filters, column .. "=is." .. tostring(value))
    return self
end

function QueryBuilder:in_(column, value)
    local formatted = ""
    if type(value) == "table" then
        formatted = "(" .. table.concat(value, ",") .. ")"
    else
        formatted = tostring(value)
    end
    table.insert(self.filters, column .. "=in." .. formatted)
    return self
end

function QueryBuilder:contains(column, value)
    table.insert(self.filters, column .. "=contains." .. tostring(value))
    return self
end

function QueryBuilder:containedBy(column, value)
    table.insert(self.filters, column .. "=containedBy." .. tostring(value))
    return self
end

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

function QueryBuilder:overlaps(column, value)
    table.insert(self.filters, column .. "=overlaps." .. tostring(value))
    return self
end

function QueryBuilder:textSearch(column, value)
    table.insert(self.filters, column .. "=textSearch." .. tostring(value))
    return self
end

function QueryBuilder:match(object)
    for k, v in pairs(object) do
        self:eq(k, v)
    end
    return self
end

function QueryBuilder:not_(column, value)
    table.insert(self.filters, column .. "=not.eq." .. tostring(value))
    return self
end

function QueryBuilder:or_(filterString)
    table.insert(self.filters, "or=(" .. tostring(filterString) .. ")")
    return self
end

function QueryBuilder:filter(column, operator, value)
    table.insert(self.filters, column .. "=" .. operator .. "." .. tostring(value))
    return self
end

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
    self._order = orderStr
    return self
end

function QueryBuilder:limit(n)
    self._limit = n
    return self
end

function QueryBuilder:range(from, to)
    self._range = { from = from, to = to }
    return self
end

function QueryBuilder:abortSignal(signal)
    self._abortSignal = signal
    return self
end

function QueryBuilder:single()
    print("QueryBuilder:single")
    self.singleRow = true
    return self
end

function QueryBuilder:maybeSingle()
    self._maybeSingle = true
    return self
end

function QueryBuilder:csv()
    self._csv = true
    return self
end

function QueryBuilder:select(columns)
    if columns then
        self.select_columns = columns
    end
    if self._upsert then
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

function QueryBuilder:upsert(data, options)
    print("QueryBuilder:upsert")
    self.method = "POST"
    self.operation = "upsert"
    self.data = data
    self._upsert = true
    if options and options.onConflict then
        self.on_conflict = options.onConflict
    end
    return self
end

function QueryBuilder:delete()
    self.method = "DELETE"
    self.operation = "delete"
    return self:execute()
end

function QueryBuilder:callback(cb)
    local p = self:execute()
    p:next(function(result)
        cb(result.data, result.error)
        return result
    end)
    return p
end

function QueryBuilder:await()
    print("QueryBuilder:await")
    local result = Citizen.Await(self:execute())
    return result.data, result.error
end

function QueryBuilder:buildUrl()
    local url = self.client.url .. "/rest/v1/" .. self.table
    local params = {}

    if self.operation == "select" or self.operation == "upsert" then
        table.insert(params, "select=" .. self.select_columns)
    end

    if self._upsert then
        table.insert(params, "upsert=true")
    end

    if self.on_conflict then
        table.insert(params, "on_conflict=" .. self.on_conflict)
    end

    if self._order then
        table.insert(params, "order=" .. self._order)
    end

    if self._limit then
        table.insert(params, "limit=" .. tostring(self._limit))
    end

    if #self.filters > 0 then
        for _, filter in ipairs(self.filters) do
            table.insert(params, filter)
        end
    end

    if #params > 0 then
        url = url .. "?" .. table.concat(params, "&")
    end

    print("Formed URL: " .. url)
    return url
end

function QueryBuilder:execute()
    local p = promise.new()
    local url = self:buildUrl()
    local payload = ""
    if self.method == "POST" or self.method == "PATCH" then
        payload = json.encode(self.data)
    end

    if self._abortSignal and type(self._abortSignal) == "function" and self._abortSignal() then
        p:resolve({ data = nil, error = "Aborted" })
        return p
    end

    local headers = {}
    for k, v in pairs(self.client.headers) do
        headers[k] = v
    end
    if self._range then
        headers["Range"] = string.format("%d-%d", self._range.from, self._range.to)
    end

    print("URL: " ..url)
    print("Method: ".. self.method)
    print("Payload: " .. dump(payload))
    print("Headers: " .. dump(headers))

    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders, errorData)
        local result = { data = nil, error = nil }
        print("Status code is " .. statusCode)
        print("Error data" ..errorData)
        if statusCode == 0 then
            result.error = "HTTP request failed (no response received)"
        else
            if self._csv then
                result.data = responseText
            else
                print(dump(result))
                print(dump(result.data))
                local successDecode, decoded = pcall(json.decode, responseText)
                print(dump(decoded))
                if successDecode then
                    if self._maybeSingle then
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
                        dump(result)
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

function RPCBuilder:constructor(client, functionName, params, options)
    self.client = client
    self.functionName = functionName
    self.params = params or {}
    self.options = options or {}
end

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

function RPCBuilder:callback(cb)
    local p = self:execute()
    p:next(function(result)
        cb(result.data, result.error)
        return result
    end)
    return p
end

function RPCBuilder:await()
    local result = Citizen.Await(self:execute())
    return result.data, result.error
end

----------------------------------------
-- MODULE EXPORT: SUPABASE
----------------------------------------

-- Export createClient as a method on an export table so that colon syntax works as expected.
function createClient(url, key)
    print("is key   " .. key)
    print("is url   " .. url)
    return SupabaseClient:new(url, key)
end

function testClient(url, key)
    local supabase = SupabaseClient:new(url, key)

    -- local insertData, insertError = supabase:from("players")
    --     :insert({ name = "TestPlayer" })
    --     :await()

    local data, error = supabase
        :from("players")
        :upsert({ name = "TestPlayer" }, { onConflict = "name" })
        :single()
        :await()

    if insertError then
        print("[testClient] Insert Error:", insertError)
        return
    else
        print("[testClient] Inserted data:", json.encode(insertData))
    end
end

exports("createClient", createClient)
exports("testClient", testClient)