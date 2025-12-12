-- Lua script for wrk to test create endpoint
counter = 0

request = function()
    counter = counter + 1
    local url = "https://example.com/test/" .. counter .. "?param=" .. math.random(10000)
    local body = '{"url":"' .. url .. '"}'
    
    return wrk.format("POST", "/api/v1/shorten", {
        ["Content-Type"] = "application/json"
    }, body)
end

