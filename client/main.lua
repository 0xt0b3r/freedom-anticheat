FAC.ServerConfigLoaded = false

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    FAC.TriggerServerEvent('freedomanticheat:playerResourceStarted')
end)

Citizen.CreateThread(function()
    FAC.LaodServerConfig()

    Citizen.Wait(1000)

    while not FAC.ServerConfigLoaded do
        Citizen.Wait(1000)

        FAC.LaodServerConfig()
    end

    return
end)

FAC.LaodServerConfig = function()
    if (not FAC.ServerConfigLoaded) then
        FAC.TriggerServerCallback('freedomanticheat:getServerConfig', function(config)
            FAC.Config = config
            FAC.Config.BlacklistedWeapons = {}
            FAC.Config.BlacklistedVehicles = {}
            FAC.Config.HasBypass = FAC.Config.HasBypass or false

            for _, blacklistedWeapon in pairs(Config.BlacklistedWeapons) do
                FAC.Config.BlacklistedWeapons[blacklistedWeapon] = GetHashKey(blacklistedWeapon)
            end

            for _, blacklistedVehicle in pairs(Config.BlacklistedVehicles) do
                FAC.Config.BlacklistedVehicles[blacklistedVehicle] = GetHashKey(blacklistedVehicle)
            end

            FAC.ServerConfigLoaded = true
        end)
    end
end
