FAC.LoadSecurityTokens = function()
    local tokenContent = LoadResourceFile(GetCurrentResourceName(), 'data/token.json')

    if (not tokenContent) then
        local newTokenList = json.encode({})

        tokenContent = newTokenList

        SaveResourceFile(GetCurrentResourceName(), 'data/token.json', newTokenList, -1)
    end

    local storedTokens = json.decode(tokenContent)

    if (not storedTokens) then
        print('-------------------!' .. _('fatal_error') .. '!------------------\n')
        print(_('failed_to_load_tokenlist') .. '\n')
        print(_('failed_to_load_check') .. '\n')
        print('-------------------!' .. _('fatal_error') .. '!------------------\n')

        FAC.SecurityTokens = {}
    else
        FAC.SecurityTokens = storedTokens
    end

    FAC.SecurityTokensLoaded = true
end

FAC.SaveSecurityTokens = function()
    SaveResourceFile(GetCurrentResourceName(), 'data/token.json', json.encode(FAC.SecurityTokens or {}, { indent = true }), -1)
end

FAC.GetSteamIdentifier = function(source)
    if (source == nil) then
        return ''
    end

    local playerId = tonumber(source)

    if (playerId <= 0) then
        return ''
    end

    local identifiers, steamIdentifier = GetPlayerIdentifiers(source)

    for _, identifier in pairs(identifiers) do
        if (string.match(string.lower(identifier), 'steam:')) then
            steamIdentifier = identifier
        end
    end

    return steamIdentifier
end

FAC.GetClientSecurityToken = function(source, resource)
    if (FAC.SecurityTokens ~= nil and FAC.SecurityTokens[tostring(source)] ~= nil) then
        local steamIdentifier = FAC.GetSteamIdentifier(source)

        for _, resourceToken in pairs(FAC.SecurityTokens[tostring(source)]) do
            if (resourceToken.name == resource and resourceToken.steam == steamIdentifier) then
                return resourceToken
            elseif (resourceToken.name == resource) then
                table.remove(FAC.SecurityTokens[tostring(source)], _)
            end
        end
    end

    return nil
end

FAC.GenerateSecurityToken = function(source, resource)
    local currentToken = FAC.GetClientSecurityToken(source, resource)

    if (currentToken == nil) then
        local newResourceToken = {
            name = resource,
            token = FAC.RandomString(Config.TokenLength),
            time = os.time(),
            steam = FAC.GetSteamIdentifier(source),
            shared = false
        }

        if (FAC.SecurityTokens == nil) then
            FAC.SecurityTokens = {}
        end

        if (FAC.SecurityTokens[tostring(source)] == nil) then
            FAC.SecurityTokens[tostring(source)] = {}
        end

        table.insert(FAC.SecurityTokens[tostring(source)], newResourceToken)

        FAC.SaveSecurityTokens()

        return newResourceToken
    end

    return nil
end

FAC.GetCurrentSecurityToken = function(source, resource)
    local currentToken = FAC.GetClientSecurityToken(source, resource)

    if (currentToken == nil) then
        local newToken = FAC.GenerateSecurityToken(source, resource)

        if (not newToken.shared) then
            FAC.TriggerClientEvent(source, 'freedomanticheat:storeSecurityToken', newToken)
        end

        if (newToken == nil) then
            FAC.KickPlayerWithReason(source, _U('kick_type_security_token'))
            return nil
        else
            return newToken
        end
    end

    return currentToken
end

FAC.ValidateToken = function(source, resource, token)
    local currentToken = FAC.GetCurrentSecurityToken(source, resource)

    if (currentToken == nil and token == nil) then
        return true
    elseif(currentToken ~= nil and not currentToken.shared and token == nil) then
        return true
    elseif(currentToken ~= nil and currentToken.token == token) then
        return true
    end

    return false
end

FAC.ValidateOrKick = function(source, resource, token)
    if (not FAC.ValidateToken(source, resource, token)) then
        FAC.KickPlayerWithReason(_U('kick_type_security_mismatch'))
        return false
    end

    return true
end

FAC.RegisterServerEvent('freedomanticheat:storeSecurityToken', function(source, resource)
    if (FAC.SecurityTokens ~= nil and FAC.SecurityTokens[tostring(source)] ~= nil) then
        local steamIdentifier = FAC.GetSteamIdentifier(source)

        for _, resourceToken in pairs(FAC.SecurityTokens[tostring(source)]) do
            if (resourceToken.name == resource and resourceToken.steam == steamIdentifier) then
                resourceToken.shared = true
                FAC.SecurityTokens[tostring(source)][_].shared = true
            elseif (resourceToken.name == resource) then
                table.remove(FAC.SecurityTokens[tostring(source)], _)
            end
        end

        FAC.SaveSecurityTokens()
    end
end)
