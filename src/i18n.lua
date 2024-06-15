class 'i18n'

local phrases = {
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

local user_language = api.get("/settings/info").defaultLanguage or "en"
local user_translations = phrases[string.lower(user_language)] or {}
local default_translations = phrases["en"]

local function getTranslation(translations, ...)
    local paths = {...}
    local curLocation = translations
    for i=1,#paths do
        local path = paths[i]
        if (curLocation[path] == nil) then
            return nil
        elseif (i == #paths) then
            return curLocation[path]
        else
            curLocation = curLocation[path]
        end
    end
    return nil
end

function i18n:get(...)
    local translation = getTranslation(user_translations, ...)
    if not translation then
        translation = getTranslation(default_translations, ...)
    end
    if translation then
        return translation
    end
    return key
end
