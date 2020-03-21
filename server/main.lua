FAC.LoadBanList = function()
    local banlistContent = LoadResourceFile(GetCurrentResourceName(), 'data/banlist.json')

    if (not banlistContent) then
        local newBanlist = json.encode({})

        banlistContent = newBanlist

        SaveResourceFile(GetCurrentResourceName(), 'data/banlist.json', newBanlist, -1)
    end

    local banlist = json.decode(banlistContent)

    if (not banlist) then
        print('-------------------!' .. _('fatal_error') .. '!------------------\n')
        print(_('failed_to_load_banlist') .. '\n')
        print(_('failed_to_load_check') .. '\n')
        print('-------------------!' .. _('fatal_error') .. '!------------------\n')

        FAC.PlayerBans = {}
    else
        FAC.PlayerBans = banlist
    end

    FAC.BanListLoaded = true
end

FAC.LoadConfig = function()
    FAC.LoadVersion()

    FAC.Config = {
        UpdateIdentifiers   = FAC.GetConfigVariable('freedomanticheat.updateidentifiers', 'boolean'),
        GodMode             = FAC.GetConfigVariable('freedomanticheat.godmode', 'boolean'),
        Webhook             = FAC.GetConfigVariable('freedomanticheat.webhook', 'string'),
        BypassEnabled       = FAC.GetConfigVariable('freedomanticheat.bypassenabled', 'boolean'),
        VPNCheck            = FAC.GetConfigVariable('freedomanticheat.VPNCheck', 'boolean', true),
        VPNKey              = FAC.GetConfigVariable('freedomanticheat.VPNKey', 'string')
    }

    FAC.ConfigLoaded = true
end

FAC.LoadVersion = function()
    local currentVersion = LoadResourceFile(GetCurrentResourceName(), 'version')

    if (not currentVersion) then
        FAC.Version = '0.0.0'
    else
        FAC.Version = currentVersion
    end
end

FAC.AddBlacklist = function(data)
    local banlistContent = LoadResourceFile(GetCurrentResourceName(), 'data/banlist.json')

    if (not banlistContent) then
        local newBanlist = json.encode({})

        banlistContent = newBanlist

        SaveResourceFile(GetCurrentResourceName(), 'data/banlist.json', newBanlist, -1)
    end

    local banlist = json.decode(banlistContent)

    if (not banlist) then
        print('-------------------!' .. _('fatal_error') .. '!------------------\n')
        print(_('failed_to_load_banlist') .. '\n')
        print(_('failed_to_load_check') .. '\n')
        print('-------------------!' .. _('fatal_error') .. '!------------------\n')
        return
    end

    if (data.identifiers ~= nil and #data.identifiers > 0) then
        table.insert(banlist, data)

        FAC.PlayerBans = banlist

        FAC.LogBanToDiscord(data)

        SaveResourceFile(GetCurrentResourceName(), 'data/banlist.json', json.encode(banlist, { indent = true }), -1)
    end
end

FAC.BanPlayerByEvent = function(playerId, event)
    if (playerId ~= nil and playerId > 0 and not FAC.IgnorePlayer(source)) then
        local bannedIdentifiers = GetPlayerIdentifiers(playerId)

        if (bannedIdentifiers == nil or #bannedIdentifiers <= 0) then
            DropPlayer(playerId, _('user_ban_reason', _('unknown')))
            return
        end

        local playerBan = {
            name = GetPlayerName(playerId) or _('unknown'),
            reason = _('banlist_ban_reason', event),
            identifiers = bannedIdentifiers
        }

        FAC.AddBlacklist(playerBan)

        DropPlayer(playerId, _('user_ban_reason', playerBan.name))
    end
end

FAC.BanPlayerWithNoReason = function(playerId)
    if (playerId ~= nil and playerId > 0 and not FAC.IgnorePlayer(source)) then
        local bannedIdentifiers = GetPlayerIdentifiers(playerId)

        if (bannedIdentifiers == nil or #bannedIdentifiers <= 0) then
            DropPlayer(playerId, _('user_ban_reason', _('unknown')))
            return
        end

        local playerBan = {
            name = GetPlayerName(playerId) or _('unknown'),
            reason = '',
            identifiers = bannedIdentifiers
        }

        FAC.AddBlacklist(playerBan)

        DropPlayer(playerId, _('user_ban_reason', playerBan.name))
    end
end

FAC.BanPlayerWithReason = function(playerId, reason)
    if (playerId ~= nil and playerId > 0 and not FAC.IgnorePlayer(source)) then
        local bannedIdentifiers = GetPlayerIdentifiers(playerId)

        if (bannedIdentifiers == nil or #bannedIdentifiers <= 0) then
            DropPlayer(playerId, _('user_ban_reason', _('unknown')))
            return
        end

        local playerBan = {
            name = GetPlayerName(playerId) or _('unknown'),
            reason = reason,
            identifiers = bannedIdentifiers
        }

        FAC.AddBlacklist(playerBan)

        DropPlayer(playerId, _('user_ban_reason', playerBan.name))
    end
end

FAC.KickPlayerWithReason = function(playerId, reason)
    if (playerId ~= nil and playerId > 0 and not FAC.IgnorePlayer(source)) then
        DropPlayer(playerId, _('user_kick_reason', reason))
    end
end

FAC.PlayerConnecting = function(playerId, setCallback, deferrals)
    local vpnChecked = false

    deferrals.defer()
    deferrals.update(_U('checking'))

    Citizen.Wait(100)

    if (not FAC.BanListLoaded) then
        deferrals.done(_('banlist_not_loaded_kick_player'))
        return
    end

    if (FAC.IgnorePlayer(playerId)) then
        deferrals.done()
        return
    end

    local identifiers = GetPlayerIdentifiers(playerId)

    if (identifiers == nil or #identifiers <= 0) then
        DropPlayer(playerId, _('user_ban_reason', _('unknown')))
        return
    end

    for __, playerBan in pairs(FAC.PlayerBans) do
        if (FAC.TableContainsItem(identifiers, playerBan.identifiers, true)) then
            if (FAC.Config.UpdateIdentifiers) then
                FAC.CheckForNewIdentifiers(playerId, identifiers, playerBan.name, playerBan.reason)
            end

            deferrals.done(_('user_ban_reason', playerBan.name))
            return
        end
    end

    if (FAC.Config.VPNCheck) then
        if (FAC.IgnorePlayer(playerId)) then
            return
        end

        local playerIP = FAC.GetPlayerIP(playerId)

        if (playerIP == nil) then
            deferrals.done(_('ip_blocked'))
            return
        end

        while (not FAC.ConfigLoaded) do
            Citizen.Wait(10)
        end

        local ipInfo = {}

        if (FAC.CheckedIPs ~= nil and FAC.CheckedIPs[playerIP] ~= nil) then
            ipInfo = FAC.CheckedIPs[playerIP] or {}

            local blockIP =  ipInfo.block or 0

            if (blockIP == 1) then
                local ignoreIP = false

                if (FAC.WhitelistedIPsLoaded) then
                    for _, ip in pairs(FAC.WhitelistedIPs) do
                        if (ip == playerIP) then
                            ignoreIP = true
                        end
                    end
                end

                if (not ignoreIP) then
                    deferrals.done(_('ip_blocked'))
                    return
                end
            end

            vpnChecked = true
        else
            PerformHttpRequest('http://v2.api.iphub.info/ip/' .. playerIP, function(statusCode, response, headers)
                if (statusCode == 200) then
                    local rawData = response or '{}'
                    ipInfo = json.decode(rawData)

                    FAC.CheckedIPs[playerIP] = ipInfo

                    local blockIP =  ipInfo.block or 0

                    if (blockIP == 1) then
                        local ignoreIP = false

                        if (FAC.WhitelistedIPsLoaded) then
                            for _, ip in pairs(FAC.WhitelistedIPs) do
                                if (ip == playerIP) then
                                    ignoreIP = true
                                end
                            end
                        end

                        if (not ignoreIP) then
                            deferrals.done(_('ip_blocked'))
                            return
                        end
                    end
                end

                vpnChecked = true
            end, 'GET', '', {
                ['X-Key'] = FAC.Config.VPNKey
            })
        end
    end

    while not vpnChecked do
        Citizen.Wait(10)
    end

    deferrals.done()
end

FAC.CheckForNewIdentifiers = function(playerId, identifiers, name, reason)
    local newIdentifiers = {}

    for _, identifier in pairs(identifiers) do
        local identifierFound = false

        for _, playerBan in pairs(FAC.PlayerBans) do
            if (FAC.TableContainsItem({ identifier }, playerBan.identifiers, true)) then
                identifierFound = true
            end
        end

        if (not identifierFound) then
            table.insert(newIdentifiers, identifier)
        end
    end

    if (#newIdentifiers > 0) then
        local playerBan = {
            name = GetPlayerName(playerId) or _('unknown'),
            reason = _('new_identifiers_found', reason, name),
            identifiers = newIdentifiers
        }

        FAC.AddBlacklist(playerBan)
    end
end

FAC.LogBanToDiscord = function (data)
    if (FAC.Config.Webhook == nil or
        FAC.Config.Webhook == '') then
        return
    end

    local identifierString = ''

    for _, identifier in pairs(data.identifiers or {}) do
        identifierString = identifierString .. identifier

        if (_ ~= #data.identifiers) then
            identifierString = identifierString .. '\n '
        end
    end

    local discordInfo = {
        ["color"] = "15158332",
        ["type"] = "rich",
        ["title"] = _('discord_title'),
        ["description"] = _('discord_description', data.name, data.reason, identifierString),
        ["footer"] = {
            ["text"] = 'freedomAntiCheat | ' .. FAC.Version
        }
    }

    PerformHttpRequest(FAC.Config.Webhook, function(err, text, headers) end, 'POST', json.encode({ username = 'freedomAntiCheat', embeds = { discordInfo } }), { ['Content-Type'] = 'application/json' })
end

Citizen.CreateThread(function()
    while not FAC.BanListLoaded do
        FAC.LoadBanList()

        Citizen.Wait(10)
    end

    while not FAC.ConfigLoaded do
        FAC.LoadConfig()

        Citizen.Wait(10)
    end

    while not FAC.WhitelistedIPsLoaded do
        FAC.LoadWhitelistedIPs()

        Citizen.Wait(10)
    end
end)

FAC.RegisterServerCallback('freedomanticheat:getServerConfig', function(source, cb)
    while not FAC.ConfigLoaded do
        Citizen.Wait(10)
    end

    if ((FAC.Config.GodMode or false) and FAC.IgnorePlayer(source)) then
        FAC.Config.GodMode = false
    end

    FAC.Config.HasBypass = FAC.IgnorePlayer(source)

    cb(FAC.Config)
end)

FAC.RegisterServerCallback('freedomanticheat:getRegisteredCommands', function(source, cb)
    cb(GetRegisteredCommands())
end)

FAC.RegisterServerEvent('freedomanticheat:banPlayer', function(source, type, item)
    local _type = type or 'default'
    local _item = item or 'none'

    _type = string.lower(_type)

    if (_type == 'default') then
        FAC.BanPlayerWithNoReason(source)
    elseif (_type == 'godmode') then
        FAC.BanPlayerWithReason(source, _U('ban_type_godmode'))
    elseif (_type == 'injection') then
        FAC.BanPlayerWithReason(source, _U('ban_type_injection'))
    elseif (_type == 'blacklisted_weapon') then
        FAC.BanPlayerWithReason(source, _U('ban_type_blacklisted_weapon', _item))
    elseif (_type == 'blacklisted_key') then
        FAC.BanPlayerWithReason(source, _U('ban_type_blacklisted_key', _item))
    elseif (_type == 'hash') then
        FAC.BanPlayerWithReason(source, _U('ban_type_hash'))
    elseif (_type == 'esx_shared') then
        FAC.BanPlayerWithReason(source, _U('ban_type_esx_shared'))
    elseif (_type == 'superjump') then
        FAC.BanPlayerWithReason(source, _U('ban_type_superjump'))
    elseif (_type == 'event') then
        FAC.BanPlayerByEvent(source, _item)
    end
end)

FAC.RegisterServerEvent('freedomanticheat:playerResourceStarted', function(source)
    if (FAC.StartedPlayers ~= nil and FAC.StartedPlayers[tostring(source)] ~= nil and FAC.StartedPlayers[tostring(source)]) then
        FAC.BanPlayerWithReason(source, _U('lua_executor_found'))
    end

    if (FAC.StartedPlayers[tostring(source)] == nil) then
        FAC.StartedPlayers[tostring(source)] = {
            lastResponse = os.time(os.date("!*t")),
            numberOfTimesFailed = 0
        }
    end
end)

FAC.RegisterServerEvent('freedomanticheat:logToConsole', function(source, message)
    print(message)
end)
