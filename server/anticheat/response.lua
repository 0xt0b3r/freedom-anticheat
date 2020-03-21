local CheckIfClientResourceIsRunningTriggerd = false

FAC.RegisterServerEvent('freedomanticheat:stillAlive', function(source)
    if (FAC.StartedPlayers[tostring(source)] == nil) then
        FAC.StartedPlayers[tostring(source)] = {
            lastResponse = os.time(os.date("!*t")),
            numberOfTimesFailed = 0
        }
    end

    FAC.StartedPlayers[tostring(source)].lastResponse = os.time(os.date("!*t"))
end)

Citizen.CreateThread(function()
    Citizen.Wait(5000)

    if (not CheckIfClientResourceIsRunningTriggerd) then
        CheckIfClientResourceIsRunning()
        CheckIfClientResourceIsRunningTriggerd = true
    end
end)

RegisterServerEvent('es:firstJoinProper')
AddEventHandler('es:firstJoinProper', function()
    local _source = source

    if (FAC.StartedPlayers[tostring(_source)] == nil) then
        FAC.StartedPlayers[tostring(_source)] = {
            lastResponse = os.time(os.date("!*t")),
            numberOfTimesFailed = 0
        }
    end
end)

function CheckIfClientResourceIsRunning()
    CheckIfClientResourceIsRunningTriggerd = true

    for _, playerId in pairs(GetPlayers()) do
        if (FAC.StartedPlayers[tostring(playerId)] == nil) then
            FAC.StartedPlayers[tostring(playerId)] = {
                lastResponse = os.time(os.date("!*t")),
                numberOfTimesFailed = 0
            }
        end
    end

    if (FAC.StartedPlayers == nil) then
        FAC.StartedPlayers = {}
    end

    for playerId, data in pairs(FAC.StartedPlayers) do
        if (playerId ~= nil and tonumber(playerId) ~= 0) then
            local banned = false

            if (FAC.StartedPlayers[playerId].numberOfTimesFailed > 5) then
                FAC.BanPlayerWithReason(tonumber(playerId), _U('ban_type_client_files_blocked'))
                banned = true
            end

            if (not banned) then
                if ((FAC.StartedPlayers[playerId].lastResponse + 100) < os.time(os.date("!*t"))) then
                    FAC.StartedPlayers[playerId].numberOfTimesFailed = FAC.StartedPlayers[playerId].numberOfTimesFailed + 1
                end

                FAC.TriggerClientCallback(tonumber(playerId), 'freedomanticheat:stillAlive', function()
                    if (FAC.StartedPlayers[playerId] ~= nil) then
                        FAC.StartedPlayers[playerId].lastResponse = os.time(os.date("!*t"))

                        if (FAC.StartedPlayers[playerId].numberOfTimesFailed > 0) then
                            FAC.StartedPlayers[playerId].numberOfTimesFailed = FAC.StartedPlayers[playerId].numberOfTimesFailed - 1
                        end
                    end
                end)
            end
        end
    end

    SetTimeout(60000, CheckIfClientResourceIsRunning)
end

RegisterServerEvent('playerDropped')
AddEventHandler('playerDropped', function()
    local _source = source

    if (FAC.StartedPlayers ~= nil and FAC.StartedPlayers[tostring(_source)] ~= nil) then
        FAC.StartedPlayers[tostring(_source)] = nil
    end
end)
