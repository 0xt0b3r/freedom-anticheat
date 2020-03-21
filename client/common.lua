AddEventHandler('freedomanticheat:getSharedObject', function(cb)
    cb(FAC)
end)

function getSharedObject()
    return FAC
end

RegisterNetEvent('freedomanticheat:triggerClientCallback')
AddEventHandler('freedomanticheat:triggerClientCallback', function(name, requestId, ...)
    FAC.TriggerClientCallback(name, function(...)
        TriggerServerEvent('freedomanticheat:clientCallback', requestId, ...)
    end, ...)
end)

RegisterNetEvent('freedomanticheat:triggerClientEvent')
AddEventHandler('freedomanticheat:triggerClientEvent', function(name, ...)
    FAC.TriggerClientEvent(name, ...)
end)
