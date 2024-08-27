local dutyBlips = {}

RegisterNetEvent('createDutyBlip')
AddEventHandler('createDutyBlip', function(department, badgeNumber, callsign)
    local playerPed = PlayerPedId()
    local blip = AddBlipForEntity(playerPed)
    
    SetBlipSprite(blip, 1)
    SetBlipColour(blip, 3)
    SetBlipScale(blip, 1.0)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(department .. " (" .. callsign .. ", Badge " .. badgeNumber .. ")")
    EndTextCommandSetBlipName(blip)

    dutyBlips[PlayerId()] = blip
end)

RegisterNetEvent('removeDutyBlip')
AddEventHandler('removeDutyBlip', function()
    local blip = dutyBlips[PlayerId()]
    if blip then
        RemoveBlip(blip)
        dutyBlips[PlayerId()] = nil
    end
end)
