FAC.RegisterClientEvent('freedomanticheat:storeSecurityToken', function(newToken)
    if (FAC.SecurityTokens == nil) then
        FAC.SecurityTokens = {}
    end

    FAC.SecurityTokens[newToken.name] = newToken

    FAC.TriggerServerEvent('freedomanticheat:storeSecurityToken', newToken.name)
end)

FAC.GetResourceToken = function(resource)
    if (resource ~= nil) then
        local securityTokens = FAC.SecurityTokens or {}
        local resourceToken = securityTokens[resource] or {}
        local token = resourceToken.token or nil

        return token
    end

    return nil
end
