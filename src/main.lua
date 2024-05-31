-- Fibaro HC3 Quick App for Wallbox
-- Version 1.0

local translations = {
    en = {
        labels = {
            power_limit = "Power limit",
        },
        errors = {
            unknown = "Unexpected error",
            var_username_undefined = "Variable 'username' not defined",
            var_password_undefined = "Variable 'password' not defined",
            var_chargerId_undefined = "Variable 'chargerId' not defined",
            [1] = "Error connecting to Wallbox API",
            [2] = "Error getting token from Wallbox API, check username and password",
            [3] = "Error getting status from Wallbox API, check chargerId (ie. serial number)",
            [4] = "Error updating charger from Wallbox API",
        },
        status = {
            unknown = "Unknown status",
            waiting = "Waiting for status ...",
            [0] = "Disconnected",
            [14] = "Error",
            [15] = "Error",
            [161] = "Ready",
            [162] = "Ready",
            [163] = "Disconnected",
            [164] = "Waiting",
            [165] = "Locked",
            [166] = "Updating",
            [177] = "Scheduled",
            [178] = "Paused",
            [179] = "Scheduled",
            [180] = "Waiting for car demand",
            [181] = "Waiting for car demand",
            [182] = "Paused",
            [183] = "Waiting in queue by Power Sharing",
            [184] = "Waiting in queue by Power Sharing",
            [185] = "Waiting in queue by Power Boost",
            [186] = "Waiting in queue by Power Boost",
            [187] = "Waiting MID failed",
            [188] = "Waiting MID safety margin exceeded",
            [189] = "Waiting in queue by Eco-Smart",
            [193] = "Charging",
            [194] = "Charging",
            [195] = "Charging",
            [196] = "Discharging",
            [209] = "Locked",
            [210] = "Locked - Car connected",
        },
    },
    fr = {
        labels = {
            power_limit ="Limite de puissance",
        },
        errors = {
            unknown = "Erreur inattendue",
            var_username_undefined = "Variable 'username' non définie",
            var_password_undefined = "Variable 'password' non définie",
            var_chargerId_undefined = "Variable 'chargerId' non définie",
            [1] = "Erreur lors de la connection à l'API Wallbox",
            [2] = "Erreur lors de la récupération du token depuis l'API Wallbox, vérifiez le login et le mot de passe",
            [3] = "Erreur lors de la récupération du statut depuis l'API Wallbox, vérifiez l'id du chargeur (numéro de série)",
            [4] = "Erreur lors de la mise à jour du chargeur depuis l'API Wallbox",
        },
        status = {
            unknown = "Statut inconnu",
            waiting = "En attente du statut ...",
            [0] = "Débranché",
            [14] = "Erreur",
            [15] = "Erreur",
            [161] = "Prêt",
            [162] = "Prêt",
            [163] = "Débranché",
            [164] = "En attendant",
            [165] = "Verrouillé",
            [166] = "Mise à jour en cours",
            [177] = "Programmé",
            [178] = "En pause",
            [179] = "Programmé",
            [180] = "En attente de la demande du véhicule",
            [181] = "En attente de la demande du véhicule",
            [182] = "En pause",
            [183] = "Mis en file d'attente par Power Sharing",
            [184] = "Mis en file d'attente par Power Sharing",
            [185] = "Mis en file d'attente par Power Boost",
            [186] = "Mis en file d'attente par Power Boost",
            [187] = "Échec attente MID",
            [188] = "Marge de sécurité dépassée attente MID",
            [189] = "Mis en file d'attente par Eco-Smart",
            [193] = "En charge",
            [194] = "En charge",
            [195] = "En charge",
            [196] = "En décharge",
            [209] = "Verrouillé",
            [210] = "Verrouillé - Véhicule branché",
        },
    },
}

function QuickApp:statusToString(s)
    local strStatus = self.trad.status[s]
    if strStatus then
        return strStatus
    end
    return self.trad.status.unknown
end

function QuickApp:errorToString(e)
    local strError = self.trad.errors[e]
    if strError then
        return strError
    end
    return self.trad.errors.unknown
end

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
        function(sucess, token_or_err)
            if sucess then
				self:trace("New Token loaded")
                self.wallbox_token = token_or_err
            end
            callback(sucess, token_or_err)
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
                wallbox:getChargerStatus(
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
    if not tools:checkVG("Wallbox_"..self.charger_id) then
        tools:createVG("Wallbox_"..self.charger_id, self:statusToEnum(status.data.chargerData.status), self:getStatusEnum())
    else
        tools:setVG("Wallbox_"..status.data.chargerData.id, self:statusToEnum(status.data.chargerData.status))
    end
    -- Lock / Unlock
    if (status.data.chargerData.locked == 1) then
        if (fibaro.getValue(self.id,"value") ~= false) then
            self:updateProperty("value", false)
            --hub.alert('push', {2}, self.wallbox_name ..' Locked')
        end
    else
        if (fibaro.getValue(self.id,"value") ~= true) then
            self:updateProperty("value", true)
            --hub.alert('push', {2}, self.wallbox_name .. ' Unlocked')
        end
    end

    -- Charging current
    local maxAvailableCurrent = status.data.chargerData.maxAvailableCurrent
    if (maxAvailableCurrent ~= tools.getView(self,"max_charging_current","max")) then -- max
        self:updateView("max_charging_current","max", tostring(maxAvailableCurrent))
    end
    local maxChargingCurrent = status.data.chargerData.maxChargingCurrent
    if (maxChargingCurrent ~= tools.getView(self,"max_charging_current","value")) then -- value
        self:updateView("max_charging_current","value", tostring(maxChargingCurrent))
    end

    if (os.time() >= self.actions_locked_until) then
        -- Status
        local wbStatus = status.data.chargerData.status
        self:updateView("status","text", self:statusToString(wbStatus))

        if wbStatus == 193 or wbStatus == 194 or wbStatus == 195 then
            -- Charging
            self:updateView("button_start","visible", false)
            self:updateView("button_stop","visible", true)
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
function QuickApp:delayRefreshStatus()
    self.actions_locked_until = os.time() + 5 * 1000
    self:updateView("button_start","visible", false)
    self:updateView("button_stop","visible", false)
    self:updateView("button_reschedule","visible", false)
    self:updateView("status","text", self.trad.status.waiting)
    -- wait 5s to refresh status
    fibaro.setTimeout(
        5*1000,
        function()
            self.actions_locked_until = 0
            self:refreshChargerStatus()
            -- wait 2s more to rerefresh status
            fibaro.setTimeout(
                2*1000,
                function()
                    self:refreshChargerStatus()
                end
            )
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

function QuickApp:loop()
    fibaro.setTimeout(
        1*60*1000,
        function()
            self:refreshChargerStatus()
            self:loop()
        end
    ) -- all 1 min
end

function QuickApp:initAndLoop()
    self:refreshChargerStatus(
        function(success, status_or_err)
            if success then
                self:loop()
            end
        end
    )
end

function QuickApp:onInit()
    self:trace("-----------------------------")
    self:trace("Initialisation Wallbox QA")
    self:trace("-----------------------------")

    self.language = api.get("/settings/info").defaultLanguage or nil
    self.trad = translations[string.lower(self.language)]
    if not self.trad then
        self.language = "en"
        self.trad = translations["en"]
    end

    -- Initialise max charging current slider
    self:updateView("max_charging_current","min","6")
    self:updateView("max_charging_current","min","6")
    self:updateView("max_charging_current","max", "32")
    self:updateView("max_charging_current", "value", "32")
    self:updateView("label_max_charging_current", "text", self.trad.labels.power_limit)

    -- Get variables from Quickapp config
    self.username = self:getVariable("username")
    self.password = self:getVariable("password")
    self.charger_id = self:getVariable("chargerId")
    if not self.username or self.username == "" or self.username == "-" then
        self:error(self.trad.errors.var_username_undefined)
        self:updateView("status", "text", self.trad.errors.var_username_undefined)
    elseif not self.password or self.password == "" or self.password == "-" then
        self:error(self.trad.errors.var_password_undefined)
        self:updateView("status", "text", self.trad.errors.var_password_undefined)
    elseif not self.charger_id or self.charger_id == "" or self.charger_id == "-" then
        self:error(self.trad.errors.var_chargerId_undefined)
        self:updateView("status", "text", self.trad.errors.var_chargerId_undefined)
    else
        -- Get Quickapp name
        self.wallbox_name = api.get("/devices/"..plugin.mainDeviceId).name

        self.wallbox_token = "-"
        self.actions_locked_until = 0

        self:initAndLoop()
    end
end

function QuickApp:turnOn()
    self:trace("binary switch turned on")
    self:getChargerStatus(
        function(success, status_or_err)
            if success then
                if status_or_err.data.chargerData.locked == 1 then
                    self:unlockCharger(
                        function(success, status_or_err)
                            if success then
                                self:synchroniseQuickAppState(status_or_err)
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
                if status_or_err.data.chargerData.locked == 0 then
                    self:lockCharger(
                        function(success, status_or_err)
                            if success then
                                self:synchroniseQuickAppState(status_or_err)
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
                local wbStatus = status_or_err.data.chargerData.status
                if wbStatus == 193 or wbStatus == 194 or wbStatus == 195 then
                    self:pauseCharger(
                        function(success, status_or_err)
                            if success then
                                self:delayRefreshStatus()
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
                local wbStatus = status_or_err.data.chargerData.status
                if wbStatus == 177 or wbStatus == 178 or wbStatus == 179 or wbStatus == 182 then
                    self:resumeCharger(
                        function(success, status_or_err)
                            if success then
                                self:delayRefreshStatus()
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
                local wbStatus = status_or_err.data.chargerData.status
                if wbStatus == 178 or wbStatus == 182 then
                    self:rescheduleCharger(
                        function(success, status_or_err)
                            if success then
                                self:delayRefreshStatus()
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
            else
				self:error(status_or_err.msg)
                self:updateView("status", "text", self:errorToString(status_or_err.code))
            end
        end
    )
end
