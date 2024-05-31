-- Wallbox API specifications from https://github.com/SKB-CGN/wallbox

-- Status codes
-- 0 = Disconnected
-- 14 = Error
-- 15 = Error
-- 161 = Ready
-- 162 = Ready
-- 163 = Disconnected
-- 164 = Waiting
-- 165 = Locked
-- 166 = Updating
-- 177 = Scheduled
-- 178 = Paused
-- 179 = Scheduled
-- 180 = Waiting for car demand
-- 181 = Waiting for car demand
-- 182 = Paused
-- 183 = Waiting in queue by Power Sharing
-- 184 = Waiting in queue by Power Sharing
-- 185 = Waiting in queue by Power Boost
-- 186 = Waiting in queue by Power Boost
-- 187 = Waiting MID failed
-- 188 = Waiting MID safety margin exceeded
-- 189 = Waiting in queue by Eco-Smart
-- 193 = Charging
-- 194 = Charging
-- 195 = Charging
-- 196 = Discharging
-- 209 = Locked
-- 210 = Locked - Car connected

-- Errors codes
-- 1 = Error connecting to Wallbox API
-- 2 = Error getting token from Wallbox API, check username and password
-- 3 = Error getting status from Wallbox API, check chargerId
-- 4 = Error updating charger from Wallbox API

local WALLBOX_AUTHENTICATION_URL = "https://api.wall-box.com/auth/token/user"
local WALLBOX_CHARGER_URL = "https://api.wall-box.com/v2/charger/"
local WALLBOX_CHARGERS_URL = "https://api.wall-box.com/v3/chargers/"
local WALLBOX_REMOTE_ACTION = "/remote-action"

local httpClient = net.HTTPClient()

wallbox = {}

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function encodeBase64(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- Get token from Wallbox API
function wallbox:getToken(username, password, callback)

 	httpClient:request(WALLBOX_AUTHENTICATION_URL, {
 		options = {
 			method = "POST",
         	headers = {
                ["Authorization"] = "Basic " .. encodeBase64(username .. ":" .. password),
                ["Accept"] = "application/json, text/plain, */*",
                ["Content-Type"] = "application/json;charset=utf-8",
 			}
 		},
 		success = function(response)
            if response.status ~= 200 then
                callback(false, {code=2, msg="Error getting token from Wallbox API, check username and password"})
                return;
            end
            local success, json_or_err = pcall(json.decode, response.data)
         	if success and json_or_err.jwt then
                callback(true, json_or_err.jwt)
        	else
                callback(false, {code=2, msg="Error getting token from Wallbox API"})
            end
        end,
        error = function(err)
            callback(false, {code=1, msg="Error connecting to Wallbox API"})
        end,
 	})
end

-- Get charger status from Wallbox API
function wallbox:getChargerStatus(token, charger_id, callback)

 	httpClient:request(WALLBOX_CHARGER_URL .. charger_id, {
 		options = {
 			method = "GET",
         	headers = {
                ["Authorization"] = "Bearer " .. token,
                ["Accept"] = "application/json, text/plain, */*",
                ["Content-Type"] = "application/json;charset=utf-8",
 			}
 		},
 		success = function(response)
            if response.status ~= 200 then
                callback(false, {code=3, msg="Error getting status from Wallbox API, check charger id (ie. serial number)"})
                return;
            end
            local success, json_or_err = pcall(json.decode, response.data)
         	if success then
                callback(true, json_or_err)
        	else
                callback(false, {code=3, msg="Error getting status from Wallbox API"})
            end
        end,
        error = function(err)
            callback(false, {code=1, msg="Error connecting to Wallbox API"})
        end,
 	})
end

-- Update charger from Wallbox API
function wallbox:updateCharger(token, charger_id, jsonInput, callback)

    local meth = "PUT"
    local url = WALLBOX_CHARGER_URL .. charger_id

    if (jsonInput.action) then
        meth = "POST"
        url = WALLBOX_CHARGERS_URL .. charger_id .. WALLBOX_REMOTE_ACTION
    end

 	httpClient:request(url, {
 		options = {
 			method = meth,
         	headers = {
                ["Authorization"] = "Bearer " .. token,
                ["Accept"] = "application/json, text/plain, */*",
                ["Content-Type"] = "application/json;charset=utf-8",
 			},
            data = json.encode(jsonInput)
 		},
 		success = function(response)
            if response.status ~= 200 then
                callback(false, {code=4, msg="Error updating charger status from Wallbox API : " .. response.status})
                return;
            end
            local success, json_or_err = pcall(json.decode, response.data)
         	if success then
                if meth == "PUT" then
                    -- API /v2/charger/ return status
                    callback(true, json_or_err)
                else
                    -- API /v3/chargers/ do not return status
                    self:getChargerStatus(token, charger_id, callback)
                end
        	else
                callback(false, {code=4, msg="Error updating charger status from Wallbox API"})
            end
        end,
        error = function(err)
            callback(false, {code=1, msg="Error connecting to Wallbox API"})
        end,
 	})
end
