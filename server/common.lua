FAC                         = {}
FAC.StartedPlayers          = {}
FAC.ServerCallbacks         = {}
FAC.ServerEvents            = {}
FAC.ClientCallbacks         = {}
FAC.ClientEvents            = {}
FAC.PlayerBans              = {}
FAC.BanListLoaded           = false
FAC.Config                  = {}
FAC.ConfigLoaded            = false
FAC.SecurityTokens          = {}
FAC.SecurityTokensLoaded    = false
FAC.WhitelistedIPs          = {}
FAC.WhitelistedIPsLoaded    = false
FAC.CheckedIPs              = {}
FAC.Version                 = '0.0.0'

AddEventHandler('freedomanticheat:getSharedObject', function(cb)
    cb(FAC)
end)

function getSharedObject()
    return FAC
end

RegisterServerEvent('freedomanticheat:triggerServerCallback')
AddEventHandler('freedomanticheat:triggerServerCallback', function(name, requestId, token, ...)
    local _source = source

    if (FAC.ValidateOrKick(_source, GetCurrentResourceName(), token)) then
        FAC.TriggerServerCallback(name, _source, function(...)
            TriggerClientEvent('freedomanticheat:serverCallback', _source, requestId, ...)
        end, ...)
    end
end)

RegisterServerEvent('freedomanticheat:triggerServerEvent')
AddEventHandler('freedomanticheat:triggerServerEvent', function(name, token, ...)
    local _source = source

    if (FAC.ValidateOrKick(_source, GetCurrentResourceName(), token)) then
        FAC.TriggerServerEvent(name, _source, ...)
    end
end)

AddEventHandler('playerConnecting', function(name, setCallback, deferrals)
    FAC.PlayerConnecting(source, setCallback, deferrals)
end)

FAC.GetConfigVariable = function(name, _type, _default)
    _type = _type or 'string'
    _default = _default or ''

    local value = GetConvar(name, _default) or _default

    if (string.lower(_type) == 'string') then
        return tostring(value)
    end

    if (string.lower(_type) == 'boolean' or
        string.lower(_type) == 'bool') then
        return (string.lower(value) == 'true' or value == true or tostring(value) == '1' or tonumber(value) == 1)
    end

    return value
end
