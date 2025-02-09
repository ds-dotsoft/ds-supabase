-- server.lua
-- Supabase JS-like Client for FiveM (Asynchronous Only with Promise and Callback Support)
-- Exported as "ds-supabase"
--
-- Example usage:
--   local supabase = exports["ds-supabase"].createClient("https://your-project.supabase.co", "your-supabase-key")
--
--   -- Using await method:
--   local data, error = supabase:from("users")
--       :upsert({ id = 42, handle = "saoirse", display_name = "Saoirse" }, { onConflict = "handle" })
--       :select()
--       :await()
--
--   -- Using callback method:
--   supabase:from("users")
--       :upsert({ id = 42, handle = "saoirse", display_name = "Saoirse" }, { onConflict = "handle" })
--       :select()
--       :callback(function(data, error)
--           if error then
--               print("Error:", error)
--           else
--               print("Data:", data)
--           end
--       end)

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

-- Chainable filter methods.
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

-- Upsert method accepts the data to upsert and an optional options table.
-- The options table can contain { onConflict = "<column>" }.
function QueryBuilder:upsert(data, options)
  self.data = data
  self.upsert = true
  if options and options.onConflict then
    self.on_conflict = options.onConflict
  end
  return self
end

-- Terminal method: select.
-- If upsert flag is true, the HTTP method will be "POST" (to perform the upsert)
-- and the operation will be "upsert"; otherwise, it defaults to a GET for select.
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
