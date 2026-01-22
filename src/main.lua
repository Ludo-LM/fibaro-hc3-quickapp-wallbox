-- Fibaro HC3 Quick App for Wallbox
-- Version 1.1.1

local status = {
    [0] = "DISCONNECTED",
    [14] = "ERROR",
    [15] = "ERROR",
    [161] = "READY",
    [162] = "READY",
    [163] = "DISCONNECTED",
    [164] = "WAITING",
    [165] = "LOCKED",
    [166] = "UPDATING",
    [177] = "SCHEDULED",
    [178] = "PAUSED",
    [179] = "SCHEDULED",
    [180] = "WAITING_FOR_CAR_DEMAND",
    [181] = "WAITING_FOR_CAR_DEMAND",
    [182] = "PAUSED",
    [183] = "WAITING_IN_QUEUE_BY_POWER_SHARING",
    [184] = "WAITING_IN_QUEUE_BY_POWER_SHARING",
    [185] = "WAITING_IN_QUEUE_BY_POWER_BOOST",
    [186] = "WAITING_IN_QUEUE_BY_POWER_BOOST",
    [187] = "WAITING_MID_FAILED",
    [188] = "WAITING_MID_SAFETY_MARGIN_EXCEEDED",
    [189] = "WAITING_IN_QUEUE_BY_ECO_SMART",
    [193] = "CHARGING",
    [194] = "CHARGING",
    [195] = "CHARGING",
    [196] = "DISCHARGING",
    [209] = "LOCKED",
    [210] = "LOCKED_CAR_CONNECTED",
    [999] = "UNKNOWN",
}

function QuickApp:statusToEnum(s)
    local strStatus = status[s]
    if strStatus then
        return strStatus
    end
    return status[999]
end

function QuickApp:getStatusEnum()
    return {status[0], status[14], status[161], status[164], status[165], status[179], status[178], status[180], status[183], status[185], status[187], status[188], status[189], status[193], status[196], status[210], status[999]}
end

function QuickApp:statusToString(s)
    local strStatus = i18n:get("status", s)
    if strStatus then
        return strStatus
    end
    return i18n:get("status", "unknown")
end

function QuickApp:errorToString(e)
    local strError = i18n:get("errors", e)
    if strError then
        return strError
    end
    return i18n:get("errors", "unknown")
end

function QuickApp:getToken(callback)
    local token = self.wallbox_token
    if token and token ~= "-" then
        local status, jwt = pcall(jwt.decode_jwt, token)
        if jwt and jwt.claims and jwt.claims.exp and jwt.claims.username then
            if jwt.claims.username ~= self.username then
                trace:debug("Renew Token because username from existing Token '" .. jwt.claims.username  .. "' is not the same as curent username '" .. self.username .. "'")
            else
                if jwt.claims.exp < os.time() then
                    self:trace("Renew Token because existing Token for username '" .. jwt.claims.username .. "' is expired since " .. os.date("%c",jwt.claims.exp))
                else
                    self:trace("Use existing Token for username '" .. jwt.claims.username .. "' because it is still valide and will expire at " .. os.date("%c",jwt.claims.exp))
                    callback(true, token)
                    return
                end
            end
        else
            self:trace("Renew Token because existing Token is not valid")
        end
    end
    self.wallbox_token = "-"
    self:trace("Getting token from Wallbox API ...")
    wallbox:getToken(
            self.username,
            self.password,
            function(success, token_or_err)
                if success then
                    self:trace("New Token loaded")
                    self.wallbox_token = token_or_err
                end
                callback(success, token_or_err)
            end
    )
end

function QuickApp:updateCharger(jsonInput, callback)
    self:getToken(
            function(success, token_or_err)
                if (success) then
                    self:trace("Updating charger from Wallbox API ...")
                    wallbox:updateCharger(
                            token_or_err,
                            self.charger_id,
                            jsonInput,
                            function(success, status_or_err)
                                if success then
                                    self:trace("Charger updated")
                                    self:synchroniseQuickAppState(status_or_err)
                                end
                                callback(success, status_or_err)
                            end
                    )
                else
                    callback(false, token_or_err)
                end
            end
    )
end

function QuickApp:getChargerStatus(callback)
    self:getToken(
            function(success, token_or_err)
                if (success) then
                    self:trace("Getting charger status from Wallbox API ...")
                    wallbox:getExtendedChargerStatus(
                            token_or_err,
                            self.charger_id,
                            function(success, status_or_err)
                                self:trace("Charger status loaded")
                                callback(success, status_or_err)
                            end
                    )
                else
                    callback(false, token_or_err)
                end
            end
    )
end

function QuickApp:setMaxChargingCurrent(current, callback)
    self:updateCharger({maxChargingCurrent = current}, callback)
end

function QuickApp:lockCharger(callback)
    self:updateCharger({locked = 1}, callback)
end

function QuickApp:unlockCharger(callback)
    self:updateCharger({locked = 0}, callback)
end

function QuickApp:resumeCharger(callback)
    self:updateCharger({action = 1}, callback)
end

function QuickApp:pauseCharger(callback)
    self:updateCharger({action = 2}, callback)
end

function QuickApp:rescheduleCharger(callback)
    self:updateCharger({action = 9}, callback)
end

function QuickApp:synchroniseQuickAppState(status)
    if not tools:checkGlobalVariable("Wallbox_"..self.charger_id) then
        tools:createGlobalVariable("Wallbox_"..self.charger_id, self:statusToEnum(status.status_id), self:getStatusEnum())
    else
        tools:setGlobalVariable("Wallbox_"..self.charger_id, self:statusToEnum(status.status_id))
    end
    -- Lock / Unlock
    if (status.config_data.locked == 1) then
        if (fibaro.getValue(self.id,"value") ~= false) then
            self:updateProperty("value", false)
        end
    else
        if (fibaro.getValue(self.id,"value") ~= true) then
            self:updateProperty("value", true)
        end
    end

    -- Charging current
    local maxAvailableCurrent = status.config_data.max_available_current
    if (maxAvailableCurrent ~= tools:getView(self,"max_charging_current","max")) then -- max
        self:updateView("max_charging_current","max", tostring(maxAvailableCurrent))
    end
    local maxChargingCurrent = status.config_data.max_charging_current
    if (maxChargingCurrent ~= tools:getView(self,"max_charging_current","value")) then -- value
        self:updateView("max_charging_current","value", tostring(maxChargingCurrent))
    end

    self:updateView("label_max_charging_current", "text", i18n:get("labels", "power_limit") .. " " .. string.format("%.0f", maxChargingCurrent) .. "A")

    self:updateProperty("power", math.floor(status.charging_power * 1000 + 0.5))

    if (os.time() >= self.actions_locked_until) then
        -- Status
        local wbStatus = status.status_id
        local status_msg = self:statusToString(wbStatus)
        if (status.added_energy ~= 0) then
            status_msg = status_msg .. "\n⌁ " .. string.format("%.2f", status.added_energy) .. " kWh"
        end
        self:updateView("status", "text", status_msg)

        if wbStatus == 193 or wbStatus == 194 or wbStatus == 195 then
            -- Charging
            self:updateView("button_start","visible", false)
            self:updateView("button_stop","visible", true)
            -- Add added energy to status
        elseif wbStatus == 177 or wbStatus == 178 or wbStatus == 179 or wbStatus == 182 then
            -- Paused or Scheduled
            self:updateView("button_start","visible", true)
            self:updateView("button_stop","visible", false)
        else
            self:updateView("button_start","visible", false)
            self:updateView("button_stop","visible", false)
        end
        if wbStatus == 178 or wbStatus == 182 then
            -- Paused
            self:updateView("button_reschedule","visible", true)
        else
            self:updateView("button_reschedule","false", false)
        end
    end
end

-- Lock start/stop action button and status label for at less 5s
function QuickApp:lockStatusThenRefresh(lockDelay, refreshDelay, refreshCount)
    self.actions_locked_until = os.time() + lockDelay
    self:updateView("button_start","visible", false)
    self:updateView("button_stop","visible", false)
    self:updateView("button_reschedule","visible", false)
    self:updateView("status","text",i18n:get("status", "waiting"))
    -- wait 5s to refresh status
    fibaro.setTimeout(
            lockDelay,
            function()
                self.actions_locked_until = 0
                self:refreshChargerStatus()
                self:loopRefreshStatus(refreshDelay, refreshCount)
            end
    )
end

function QuickApp:refreshChargerStatus(callback)
    self:getChargerStatus(
            function(success, status_or_err)
                if success then
                    self:synchroniseQuickAppState(status_or_err)
                else
                    self:error(status_or_err.msg)
                    self:updateView("status", "text", self:errorToString(status_or_err.code))
                end
                if callback then
                    callback(success, status_or_err)
                end
            end
    )
end

function QuickApp:loopRefreshStatus(delay, count)
    fibaro.setTimeout(
            delay,
            function()
                self:refreshChargerStatus()
                if not count then
                    self:loopRefreshStatus(delay)
                else
                    local nexCount = count - 1
                    if nexCount <= 0 then
                        return
                    end
                    self:loopRefreshStatus(delay, nexCount)
                end
            end
    )
end

function QuickApp:initAndLoop()
    self:refreshChargerStatus(
            function(success, status_or_err)
                if success then
                    self:loopRefreshStatus(1*60*1000)
                end
            end
    )
end

function QuickApp:turnOn()
    self:trace("binary switch turned on")
    self:getChargerStatus(
            function(success, status_or_err)
                if success then
                    if status_or_err.config_data.locked == 1 then
                        self:unlockCharger(
                                function(success, status_or_err)
                                    if success then
                                        self:synchroniseQuickAppState(status_or_err)
                                        -- status is not up to date, need to update it in few moments
                                        self:loopRefreshStatus(3*1000, 2)
                                    else
                                        self:error(status_or_err.msg)
                                        self:updateView("status", "text", self:errorToString(status_or_err.code))
                                    end
                                end
                        )
                    else
                        self:synchroniseQuickAppState(status_or_err)
                    end
                else
                    self:error(status_or_err.msg)
                    self:updateView("status", "text", self:errorToString(status_or_err.code))
                end
            end
    )
end

function QuickApp:turnOff()
    self:trace("binary switch turned off")
    self:getChargerStatus(
            function(success, status_or_err)
                if success then
                    if status_or_err.config_data.locked == 0 then
                        self:lockCharger(
                                function(success, status_or_err)
                                    if success then
                                        self:synchroniseQuickAppState(status_or_err)
                                        -- status is not up to date, need to update it in few moments
                                        self:loopRefreshStatus(3*1000, 2)
                                    else
                                        self:error(status_or_err.msg)
                                        self:updateView("status", "text", self:errorToString(status_or_err.code))
                                    end
                                end
                        )
                    else
                        self:synchroniseQuickAppState(status_or_err)
                    end
                else
                    self:error(status_or_err.msg)
                    self:updateView("status", "text", self:errorToString(status_or_err.code))
                end
            end
    )
end

function QuickApp:onStop(event)
    self:getChargerStatus(
            function(success, status_or_err)
                if success then
                    local wbStatus = status_or_err.status_id
                    if wbStatus == 193 or wbStatus == 194 or wbStatus == 195 then
                        self:pauseCharger(
                                function(success, status_or_err)
                                    if success then
                                        -- status is not up to date, need to lock status for few seconds and update it several times later
                                        self:lockStatusThenRefresh(5*1000, 4*1000, 5)
                                    else
                                        self:error(status_or_err.msg)
                                        self:updateView("status", "text", self:errorToString(status_or_err.code))
                                    end
                                end
                        )
                    end
                else
                    self:error(status_or_err.msg)
                    self:updateView("status", "text", self:errorToString(status_or_err.code))
                end
            end
    )
end

function QuickApp:onStart(event)
    self:getChargerStatus(
            function(success, status_or_err)
                if success then
                    local wbStatus = status_or_err.status_id
                    if wbStatus == 177 or wbStatus == 178 or wbStatus == 179 or wbStatus == 182 then
                        self:resumeCharger(
                                function(success, status_or_err)
                                    if success then
                                        -- status is not up to date, need to lock status for few seconds and update it several times later
                                        self:lockStatusThenRefresh(5*1000, 4*1000, 5)
                                    else
                                        self:error(status_or_err.msg)
                                        self:updateView("status", "text", self:errorToString(status_or_err.code))
                                    end
                                end
                        )
                    end
                else
                    self:error(status_or_err.msg)
                    self:updateView("status", "text", self:errorToString(status_or_err.code))
                end
            end
    )
end

function QuickApp:onReschedule(event)
    self:getChargerStatus(
            function(success, status_or_err)
                if success then
                    local wbStatus = status_or_err.status_id
                    if wbStatus == 178 or wbStatus == 182 then
                        self:rescheduleCharger(
                                function(success, status_or_err)
                                    if success then
                                        -- status is not up to date, need to lock status for few seconds and update it several times later
                                        self:lockStatusThenRefresh(5*1000, 4*1000, 5)
                                    else
                                        self:error(status_or_err.msg)
                                        self:updateView("status", "text", self:errorToString(status_or_err.code))
                                    end
                                end
                        )
                    end
                else
                    self:error(status_or_err.msg)
                    self:updateView("status", "text", self:errorToString(status_or_err.code))
                end
            end
    )
end

function QuickApp:onRefresh(event)
    self:refreshChargerStatus()
end

function QuickApp:onChangeMaxChargingCurrent(event)
    local maxChargingCurrent = event.values[1]
    self:trace("Change max charging current " .. maxChargingCurrent)
    self:setMaxChargingCurrent(
            tonumber(maxChargingCurrent),
            function(success, status_or_err)
                if success then
                    self:synchroniseQuickAppState(status_or_err)
                    local wbStatus = status_or_err.status_id
                    if wbStatus == 193 or wbStatus == 194 or wbStatus == 195 then
                        -- Charger is charging and current may increase or decrease during next seconds, need to update it several times
                        self:loopRefreshStatus(4*1000, 5)
                    end
                else
                    self:error(status_or_err.msg)
                    self:updateView("status", "text", self:errorToString(status_or_err.code))
                end
            end
    )
end

function QuickApp:onInit()
    self:trace("-----------------------------")
    self:trace("Initialisation Wallbox QA")
    self:trace("-----------------------------")

    -- Add interface power and notification if not already done
    tools:addInterface(self, 'power')
    tools:addInterface(self, 'notification')

    -- Initialise max charging current slider
    self:updateView("max_charging_current","min","6")
    self:updateView("max_charging_current","max", "32")
    self:updateView("max_charging_current", "value", "32")
    self:updateView("label_max_charging_current", "text", i18n:get("labels", "power_limit"))

    -- Get variables from Quickapp config
    self.username = self:getVariable("username")
    self.password = self:getVariable("password")
    self.charger_id = self:getVariable("chargerId")
    if not self.username or self.username == "" or self.username == "-" then
        self:error(i18n:get("errors", "var_username_undefined"))
        self:updateView("status", "text", i18n:get("errors", "var_username_undefined"))
    elseif not self.password or self.password == "" or self.password == "-" then
        self:error(i18n:get("errors.var_password_undefined"))
        self:updateView("status", "text", i18n:get("errors", "var_password_undefined"))
    elseif not self.charger_id or self.charger_id == "" or self.charger_id == "-" then
        self:error(i18n:get("errors.var_chargerId_undefined"))
        self:updateView("status", "text", i18n:get("errors","var_chargerId_undefined"))
    else
        -- Get Quickapp name
        self.wallbox_name = api.get("/devices/"..plugin.mainDeviceId).name

        self.wallbox_token = "-"
        self.actions_locked_until = 0

        self:initAndLoop()
    end
end
