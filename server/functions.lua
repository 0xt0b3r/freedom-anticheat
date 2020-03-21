FAC.RegisterServerCallback = function(name, cb)
    FAC.ServerCallbacks[name] = cb
end

FAC.RegisterServerEvent = function(name, cb)
    FAC.ServerEvents[name] = cb
end

FAC.TriggerClientCallback = function(source, name, cb, ...)
    local playerId = tostring(source)

    if (FAC.ClientCallbacks == nil) then
        FAC.ClientCallbacks = {}
    end

    if (FAC.ClientCallbacks[playerId] == nil) then
        FAC.ClientCallbacks[playerId] = {}
        FAC.ClientCallbacks[playerId]['CurrentRequestId'] = 0
    end

    FAC.ClientCallbacks[playerId][tostring(FAC.ClientCallbacks[playerId]['CurrentRequestId'])] = cb

    TriggerClientEvent('freedomanticheat:triggerClientCallback', source, name, FAC.ClientCallbacks[playerId]['CurrentRequestId'], ...)

    if (FAC.ClientCallbacks[playerId]['CurrentRequestId'] < 65535) then
        FAC.ClientCallbacks[playerId]['CurrentRequestId'] = FAC.ClientCallbacks[playerId]['CurrentRequestId'] + 1
    else
        FAC.ClientCallbacks[playerId]['CurrentRequestId'] = 0
    end
end

FAC.TriggerClientEvent = function(source, name, ...)
    TriggerClientEvent('freedomanticheat:triggerClientEvent', source, name, ...)
end

FAC.TriggerServerCallback = function(name, source, cb, ...)
    if (FAC.ServerCallbacks ~= nil and FAC.ServerCallbacks[name] ~= nil) then
        FAC.ServerCallbacks[name](source, cb, ...)
    else
        print('[freedomAntiCheat] TriggerServerCallback => ' .. _('callback_not_found', name))
    end
end

FAC.TriggerServerEvent = function(name, source, ...)
    if (FAC.ServerEvents ~= nil and FAC.ServerEvents[name] ~= nil) then
        FAC.ServerEvents[name](source, ...)
    else
        print('[freedomAntiCheat] TriggerServerEvent => ' .. _('trigger_not_found', name))
    end
end

RegisterServerEvent('freedomanticheat:clientCallback')
AddEventHandler('freedomanticheat:clientCallback', function(requestId, ...)
    local _source = source
    local playerId = tonumber(_source)

    if (FAC.ClientCallbacks ~= nil and FAC.ClientCallbacks[playerId] ~= nil and FAC.ClientCallbacks[playerId][requestId] ~= nil) then
        FAC.ClientCallbacks[playerId][tostring(requestId)](...)
        FAC.ClientCallbacks[playerId][tostring(requestId)] = nil
    end
end)
