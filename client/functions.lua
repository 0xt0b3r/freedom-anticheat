FAC                     = {}
FAC.CurrentRequestId    = 0
FAC.ServerCallbacks     = {}
FAC.ClientCallbacks     = {}
FAC.ClientEvents        = {}
FAC.Config              = {}
FAC.SecurityTokens      = {}

FAC.RegisterClientCallback = function(name, cb)
    FAC.ClientCallbacks[name] = cb
end

FAC.RegisterClientEvent = function(name, cb)
    FAC.ClientEvents[name] = cb
end

FAC.TriggerServerCallback = function(name, cb, ...)
    FAC.ServerCallbacks[FAC.CurrentRequestId] = cb

    local token = FAC.GetResourceToken(GetCurrentResourceName())

    TriggerServerEvent('freedomanticheat:triggerServerCallback', name, FAC.CurrentRequestId, token, ...)

    if (FAC.CurrentRequestId < 65535) then
        FAC.CurrentRequestId = FAC.CurrentRequestId + 1
    else
        FAC.CurrentRequestId = 0
    end
end

FAC.TriggerServerEvent = function(name, ...)
    local token = FAC.GetResourceToken(GetCurrentResourceName())

    TriggerServerEvent('freedomanticheat:triggerServerEvent', name, token, ...)
end

FAC.TriggerClientCallback = function(name, cb, ...)
    if (FAC.ClientCallbacks ~= nil and FAC.ClientCallbacks[name] ~= nil) then
        FAC.ClientCallbacks[name](cb, ...)
    end
end

FAC.TriggerClientEvent = function(name, ...)
    if (FAC.ClientEvents ~= nil and FAC.ClientEvents[name] ~= nil) then
        FAC.ClientEvents[name](...)
    end
end

FAC.ShowNotification = function(msg)
    AddTextEntry('FACNotification', msg)
	SetNotificationTextEntry('FACNotification')
	DrawNotification(false, true)
end

FAC.RequestAndDelete = function(object, deFACh)
    if (DoesEntityExist(object)) then
        NetworkRequestControlOfEntity(object)

        while not NetworkHasControlOfEntity(object) do
            Citizen.Wait(0)
        end

        if (deFACh) then
            DeFAChEntity(object, 0, false)
        end

        SetEntityCollision(object, false, false)
        SetEntityAlpha(object, 0.0, true)
        SetEntityAsMissionEntity(object, true, true)
        SetEntityAsNoLongerNeeded(object)
        DeleteEntity(object)
    end
end

RegisterNetEvent('freedomanticheat:serverCallback')
AddEventHandler('freedomanticheat:serverCallback', function(requestId, ...)
	if (FAC.ServerCallbacks ~= nil and FAC.ServerCallbacks[requestId] ~= nil) then
		FAC.ServerCallbacks[requestId](...)
        FAC.ServerCallbacks[requestId] = nil
	end
end)
