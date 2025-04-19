local onDutyPlayers = {} 
local dutyStartTime = {} 
local onDutyBlips = {}

local REQUIRED_PERMISSION = Config.ViewAce
local WEBHOOK_URL = Config.WEBHOOK_URL

exports('GetOnDutyOfficers', function()
    return onDutyPlayers
end)

function GetPlayerDiscordID(player)
    for _, identifier in ipairs(GetPlayerIdentifiers(player)) do
        if identifier:match("discord") then
            return identifier:gsub("discord:", "")
        end
    end
    return nil
end

function GetDepartmentConfig(departmentName)
    for _, department in ipairs(Config.AllowedDepartments) do
        if department.name:lower() == departmentName:lower() then
            return department
        end
    end
    return nil
end

RegisterCommand('clockin', function(source, args, rawCommand)
    local player = tonumber(source)
    local department = args[1]
    local badgeNumber = args[2]
    local callsign = args[3]

    if not department or not badgeNumber or not callsign then
        lib.notify({
            title = 'Error',
            description = 'Usage: /clockin [department] [badge] [callsign]',
            type = 'error',
            duration = 5000
        })
        return
    end

    local departmentConfig = GetDepartmentConfig(department)
    if not departmentConfig then
        local departmentNames = {}
        for _, dep in ipairs(Config.AllowedDepartments) do
            table.insert(departmentNames, dep.name)
        end
        lib.notify({
            title = 'Error',
            description = 'Invalid department. Allowed departments: ' .. table.concat(departmentNames, ', '),
            type = 'error',
            duration = 5000
        })
        return
    end

    if not IsPlayerAceAllowed(player, departmentConfig.dutyAce) then
        lib.notify({
            title = 'Error',
            description = 'You do not have permission for ' .. departmentConfig.name .. ' duty',
            type = 'error',
            duration = 5000
        })
        return
    end

    if onDutyPlayers[player] then
        lib.notify({
            title = 'Error',
            description = 'You are already on duty.',
            type = 'error',
            duration = 5000
        })
        return
    end

    onDutyPlayers[player] = { 
        department = departmentConfig.name, 
        badge = badgeNumber, 
        callsign = callsign,
        config = departmentConfig
    }
    dutyStartTime[player] = os.time()

    TriggerClientEvent('createDutyBlip', player, departmentConfig.name, badgeNumber, callsign)

    onDutyBlips[player] = true

    local playerName = GetPlayerName(player)
    local discordID = GetPlayerDiscordID(player)
    local discordTimestamp = math.floor(os.time())

    lib.notify({
        title = 'Success',
        description = 'You have clocked in as ' .. departmentConfig.name .. ' (Callsign: ' .. callsign .. ', Badge: ' .. badgeNumber .. ').',
        type = 'success',
        duration = 5000
    })

    local embed = {
        title = ':green_circle: Clock-In Notification',
        description = string.format(
            '**%s** (Callsign: %s, Badge: %s) has clocked in.\n\n**Player ID:** %d\n**Discord:** <@%s>',
            playerName, callsign, badgeNumber, player, discordID
        ),
        color = 65280,
        fields = {
            { name = 'Department', value = departmentConfig.name, inline = true },
            { name = 'Badge Number', value = badgeNumber, inline = true },
            { name = 'Callsign', value = callsign, inline = true },
            { name = 'Clock-In Time', value = string.format('<t:%d:t>', discordTimestamp), inline = true }
        },
        footer = { text = 'Northern Bay RP - Logged by FiveM Server' }
    }
    PerformHttpRequest(WEBHOOK_URL, function(statusCode, response, headers) end, 'POST', json.encode({ embeds = { embed } }), { ['Content-Type'] = 'application/json' })
end, false)

RegisterCommand('clockout', function(source, args, rawCommand)
    local player = tonumber(source)

    if not onDutyPlayers[player] then
        lib.notify({
            title = 'Error',
            description = 'You are not currently on duty.',
            type = 'error',
            duration = 5000
        })
        return
    end

    local playerDetails = onDutyPlayers[player]
    local departmentConfig = playerDetails.config

    if not IsPlayerAceAllowed(player, departmentConfig.dutyAce) then
        lib.notify({
            title = 'Error',
            description = 'You no longer have permission for ' .. departmentConfig.name .. ' duty',
            type = 'error',
            duration = 5000
        })
        return
    end

    local startTime = dutyStartTime[player]
    local currentTime = os.time()
    local durationSeconds = currentTime - startTime
    local durationFormatted = FormatDuration(durationSeconds)

    onDutyPlayers[player] = nil
    dutyStartTime[player] = nil
        
    TriggerClientEvent('removeDutyBlip', player)
    onDutyBlips[player] = nil

    local playerName = GetPlayerName(player)
    local discordID = GetPlayerDiscordID(player)
    local discordTimestamp = math.floor(os.time())

    lib.notify({
        title = 'Success',
        description = 'You have clocked out. Duration: ' .. durationFormatted,
        type = 'success',
        duration = 5000
    })

    local embed = {
        title = ':red_circle: Clock-Out Notification',
        description = string.format(
            '**%s** (Callsign: %s, Badge: %s) has clocked out.\n\n**Duration:** %s\n**Player ID:** %d\n**Discord:** <@%s>',
            playerName,
            playerDetails.callsign,
            playerDetails.badge,
            durationFormatted,
            player,
            discordID
        ),
        color = 16711680,
        fields = {
            { name = 'Player Name:', value = playerName, inline = true },
            { name = 'User ID:', value = discordID, inline = true },
            { name = 'Department:', value = departmentConfig.name, inline = true },
            { name = 'Badge Number:', value = playerDetails.badge, inline = true },
            { name = 'Callsign', value = playerDetails.callsign, inline = true },
            { name = 'Clock-Out Time', value = string.format('<t:%d:t>', discordTimestamp), inline = true }
        },
        footer = { text = 'Northern Bay RP - Logged by FiveM Server' }
    }
    PerformHttpRequest(WEBHOOK_URL, function(statusCode, response, headers) end, 'POST', json.encode({ embeds = { embed } }), { ['Content-Type'] = 'application/json' })
end, false)

RegisterCommand('911', function(source, args, rawCommand)
    local player = tonumber(source)
    local reason = table.concat(args, ' ')
    local coords = GetEntityCoords(GetPlayerPed(player))
    local nearestPostal = getNearestPostal(coords)

    if reason == '' then
        lib.notify({
            title = 'Error',
            description = 'Usage: /911 [reason]',
            type = 'error',
            duration = 5000
        })
        return
    end

    for clockedInPlayer, info in pairs(onDutyPlayers) do
        lib.notify({
            title = '911 Call',
            description = '911 Call: ' .. reason .. ' | Postal: ' .. nearestPostal,
            type = 'inform',
            duration = 10000
        })

        local playerName = GetPlayerName(player)
        local timestamp = os.date('%Y-%m-%d %H:%M:%S')

        local embed = {
            title = ':rotating_light: 911 Call Notification',
            description = string.format(
                '**%s** has reported an emergency.\n\n**Reason:** %s\n**Nearest Postal:** %s',
                playerName,
                reason,
                nearestPostal
            ),
            color = 16711680,
            fields = {
                { name = 'Reported By', value = playerName, inline = true },
                { name = 'Time', value = timestamp, inline = true },
            },
            footer = { text = 'Your Server Name - Logged by FiveM Server' }
        }
        PerformHttpRequest(WEBHOOK_URL, function(statusCode, response, headers) end, 'POST', json.encode({ embeds = { embed } }), { ['Content-Type'] = 'application/json' })
    end
end, false)

RegisterCommand('dutytime', function(source, args, rawCommand)
    local player = tonumber(source)

    if onDutyPlayers[player] then
        local startTime = dutyStartTime[player]
        local currentTime = os.time()
        local elapsedTime = currentTime - startTime

        local hours = math.floor(elapsedTime / 3600)
        local minutes = math.floor((elapsedTime % 3600) / 60)
        local seconds = elapsedTime % 60

        local timeString = string.format("%02d:%02d:%02d", hours, minutes, seconds)

        lib.notify({
            title = 'Duty Time',
            description = 'You have been on duty for ' .. timeString .. '.',
            type = 'inform',
            duration = 5000
        })
    else
        lib.notify({
            title = 'Error',
            description = 'You are not on duty.',
            type = 'error',
            duration = 5000
        })
    end
end, false)

RegisterCommand('kickoffduty', function(source, args, rawCommand)
    local player = tonumber(source)
    local targetPlayerID = tonumber(args[1])

    if not targetPlayerID then
        lib.notify({
            title = 'Error',
            description = 'Usage: /kickoffduty [targetPlayerID]',
            type = 'error',
            duration = 5000
        })
        return
    end

    if not IsPlayerAceAllowed(player, Config.KickAce) then
        lib.notify({
            title = 'Error',
            description = 'You do not have permission to use this command.',
            type = 'error',
            duration = 5000
        })
        return
    end

    if not GetPlayerName(targetPlayerID) then
        lib.notify({
            title = 'Error',
            description = 'The specified player (ID: ' .. targetPlayerID .. ') is not online or does not exist.',
            type = 'error',
            duration = 5000
        })
        return
    end

    if onDutyPlayers[targetPlayerID] then
        onDutyPlayers[targetPlayerID] = nil
        dutyStartTime[targetPlayerID] = nil

        local playerName = GetPlayerName(targetPlayerID)
        local kickedByName = GetPlayerName(player)
        local discordID = GetPlayerDiscordID(targetPlayerID)
        local timestamp = os.date('%Y-%m-%d %H:%M:%S')
        local discordTimestamp = math.floor(os.time())

        lib.notify({
            title = 'Success',
            description = 'You have kicked ' .. playerName .. ' (ID: ' .. targetPlayerID .. ') off duty.',
            type = 'success',
            duration = 5000
        })

        local embed = {
            title = ':red_circle: Kicked Off Duty Notification',
            description = string.format(
                '**%s** (ID: %d) has been kicked off duty by **%s**.\n\n**Kicked By:** <@%s>',
                playerName,
                targetPlayerID,
                kickedByName,
                GetPlayerDiscordID(player)
            ),
            color = 16711680,
            fields = {
                { name = 'Players Name:', value = playerName, inline = true },
                { name = 'Kicked By:', value = kickedByName, inline = true },
                { name = 'Player ID:', value = targetPlayerID, inline = true },
                { name = 'Discord ID:', value = discordID, inline = true },
                { name = 'Time', value = string.format('<t:%d:t>', discordTimestamp), inline = true }
            },
            footer = { text = 'Your Server Name - Logged by FiveM Server' }
        }
        PerformHttpRequest(WEBHOOK_URL, function(statusCode, response, headers) end, 'POST', json.encode({ embeds = { embed } }), { ['Content-Type'] = 'application/json' })
    else
        lib.notify({
            title = 'Error',
            description = 'The specified player (ID: ' .. targetPlayerID .. ') is not currently on duty.',
            type = 'error',
            duration = 5000
        })
    end
end, false)

RegisterCommand('onduty', function(source, args, rawCommand)
    local player = source

    if IsPlayerAceAllowed(player, REQUIRED_PERMISSION) then
        local message = 'On-duty players:\n'

        for targetPlayerID, data in pairs(onDutyPlayers) do
            local playerName = GetPlayerName(targetPlayerID)
            local department = data.department
            local badgeNumber = data.badge
            local callsign = data.callsign
            local formattedLine = playerName .. ' (' .. department .. ', Badge ' .. badgeNumber .. ', Call Sign ' .. callsign .. ') (ID: ' .. targetPlayerID .. ')\n'
            message = message .. formattedLine
        end

        lib.notify({
            title = 'On-Duty Players',
            description = message,
            type = 'inform',
            duration = 10000
        })
    else
        lib.notify({
            title = 'Error',
            description = 'You do not have permission to use this command.',
            type = 'error',
            duration = 5000
        })
    end
end, false)

AddEventHandler('playerDropped', function(reason)
    local player = source

    if onDutyPlayers[player] then
        local playerName = GetPlayerName(player)
        local department = onDutyPlayers[player].department
        local badgeNumber = onDutyPlayers[player].badge
        local discordID = GetPlayerDiscordID(player)
        
        local dutyTime = os.time() - (dutyStartTime[player] or os.time())
            
        TriggerClientEvent('removeDutyBlip', player)
        onDutyBlips[player] = nil

        onDutyPlayers[player] = nil
        dutyStartTime[player] = nil

        local timestamp = os.date('%Y-%m-%d %H:%M:%S')
        local embed = {
            title = ':red_circle: Automatic Clock-Out',
            description = '**Officer**: ' .. playerName .. '\n\n**Department**: ' .. department .. '\n\n**Callsign**: (' .. badgeNumber .. ') has automatically clocked out after disconnecting.\n\n**Duty Time**: ' .. os.date('!%X', dutyTime) .. ' (HH:MM:SS)\n\n**(<@' .. discordID .. '>)**',
            color = 16711680,
            footer = { text = 'Player ID: ' .. player .. ' | ' .. timestamp }
        }
        PerformHttpRequest(WEBHOOK_URL, function(statusCode, response, headers) end, 'POST', json.encode({ embeds = { embed } }), { ['Content-Type'] = 'application/json' })
    end
end)

function FormatDuration(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local seconds = seconds % 60
    return string.format('%02d:%02d:%02d', hours, minutes, seconds)
end