-- server.lua
-- Complete Supabase Wrapper for FiveM with Enhanced Error Handling

-- Retrieve Supabase configuration from server convars.
local supabaseUrl = GetConvar('supabase_url', 'https://your-project.supabase.co')
local supabaseKey = GetConvar('supabase_key', 'your-supabase-key')

-- Setup HTTP headers required by Supabase.
local supabaseHeaders = {
    ["apikey"]        = supabaseKey,
    ["Authorization"] = "Bearer " .. supabaseKey,
    ["Content-Type"]  = "application/json"
}

---------------------------------------------------------------------
-- Helper: handleResponse
-- This function checks if the HTTP response status code is one of the expected codes.
-- If not, it tries to decode the response body for error details and then calls the callback
-- with a meaningful error message.
--
-- Parameters:
--   expectedCodes   - A table of expected success status codes.
--   statusCode      - The HTTP status code returned from PerformHttpRequest.
--   responseText    - The response body as text.
--   responseHeaders - The response headers.
--   callback        - The user-provided callback function.
---------------------------------------------------------------------
local function handleResponse(expectedCodes, statusCode, responseText, responseHeaders, callback)
    statusCode = tonumber(statusCode) or 0

    -- If statusCode is 0, it indicates a network error or that no response was received.
    if statusCode == 0 then
        if callback then
            callback(statusCode, "HTTP request failed (no response received)", responseHeaders)
        end
        return
    end

    -- Check if the returned status code is one of the expected success codes.
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
        if callback then
            callback(statusCode, errorMsg, responseHeaders)
        end
    else
        if callback then
            callback(statusCode, responseText, responseHeaders)
        end
    end
end

---------------------------------------------------------------------
-- Function: InsertData
-- Description: Inserts the provided data into the specified Supabase table.
-- Expected success codes: 200 or 201.
---------------------------------------------------------------------
function InsertData(tableName, data, callback)
    local url = string.format("%s/rest/v1/%s", supabaseUrl, tableName)
    local payload = json.encode(data)

    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        handleResponse({200, 201}, statusCode, responseText, responseHeaders, callback)
    end, "POST", payload, supabaseHeaders)
end
exports('InsertData', InsertData)

---------------------------------------------------------------------
-- Function: QueryData
-- Description: Retrieves data from the specified Supabase table.
-- Expected success code: 200.
---------------------------------------------------------------------
function QueryData(tableName, queryParams, callback)
    local url = string.format("%s/rest/v1/%s", supabaseUrl, tableName)
    if queryParams and queryParams ~= "" then
        url = url .. "?" .. queryParams
    end

    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        handleResponse({200}, statusCode, responseText, responseHeaders, callback)
    end, "GET", "", supabaseHeaders)
end
exports('QueryData', QueryData)

---------------------------------------------------------------------
-- Function: UpdateData
-- Description: Updates existing records in the specified Supabase table.
-- Expected success code: 204.
---------------------------------------------------------------------
function UpdateData(tableName, data, queryParams, callback)
    local url = string.format("%s/rest/v1/%s", supabaseUrl, tableName)
    if queryParams and queryParams ~= "" then
        url = url .. "?" .. queryParams
    end
    local payload = json.encode(data)

    -- Using PATCH for partial updates.
    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        handleResponse({204}, statusCode, responseText, responseHeaders, callback)
    end, "PATCH", payload, supabaseHeaders)
end
exports('UpdateData', UpdateData)

---------------------------------------------------------------------
-- Function: DeleteData
-- Description: Deletes records from the specified Supabase table.
-- Expected success code: 204.
---------------------------------------------------------------------
function DeleteData(tableName, queryParams, callback)
    local url = string.format("%s/rest/v1/%s", supabaseUrl, tableName)
    if queryParams and queryParams ~= "" then
        url = url .. "?" .. queryParams
    end

    PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
        handleResponse({204}, statusCode, responseText, responseHeaders, callback)
    end, "DELETE", "", supabaseHeaders)
end
exports('DeleteData', DeleteData)

---------------------------------------------------------------------
-- Optional Debug Command
-- Use this command (/supatest <tableName> [queryParams]) to test connectivity with Supabase.
---------------------------------------------------------------------
RegisterCommand("supatest", function(source, args, rawCommand)
    if #args < 1 then
        print("Usage: /supatest <tableName> [queryParams]")
        return
    end

    local tableName = args[1]
    local queryParams = args[2] or ""
    print(("Testing Supabase query on table '%s' with params '%s'"):format(tableName, queryParams))
    QueryData(tableName, queryParams, function(statusCode, responseText, responseHeaders)
        if statusCode == 200 then
            print("Supabase test query succeeded:")
            print(responseText)
        else
            print("Supabase test query failed (status code " .. tostring(statusCode) .. "):")
            print(responseText)
        end
    end)
end, true)
