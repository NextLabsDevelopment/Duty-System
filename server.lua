local onDutyPlayers = {} 
local dutyStartTime = {} 
local onDutyBlips = {}

local REQUIRED_PERMISSION = Config.ViewAce
local WEBHOOK_URL = Config.WEBHOOK_URL

function GetPlayerDiscordID(player)
    for _, identifier in ipairs(GetPlayerIdentifiers(player)) do
        if identifier:match("discord") then
            return identifier:gsub("discord:", "")
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
        TriggerClientEvent('nd-notify:client:sendAlert', source, {
            type = 'error',
            text = 'Usage: /clockin [department] [badge] [callsign]',
            length = 5000,
            style = { ['background-color'] = ERROR_COLOR, ['color'] = TEXT_COLOR }
        })
        return
    end

    local isValidDepartment = false
    for _, allowedDepartment in ipairs(Config.AllowedDepartments) do
        if allowedDepartment:lower() == department:lower() then
            isValidDepartment = true
            break
        end
    end

    if not isValidDepartment then
        TriggerClientEvent('nd-notify:client:sendAlert', source, {
            type = 'error',
            text = 'Invalid department. Allowed departments: ' .. table.concat(Config.AllowedDepartments, ', '),
            length = 5000,
            style = { ['background-color'] = ERROR_COLOR, ['color'] = TEXT_COLOR }
        })
        return
    end

    if IsPlayerAceAllowed(player, Config.DutyAce) then
        if onDutyPlayers[player] then
            TriggerClientEvent('nd-notify:client:sendAlert', source, {
                type = 'error',
                text = 'You are already on duty.',
                length = 5000,
                style = { ['background-color'] = ERROR_COLOR, ['color'] = TEXT_COLOR }
            })
            return
        end

        onDutyPlayers[player] = { department = department, badge = badgeNumber, callsign = callsign }
        dutyStartTime[player] = os.time()

        TriggerClientEvent('createDutyBlip', player, department, badgeNumber, callsign)
        onDutyBlips[player] = true

        local playerName = GetPlayerName(player)
        local discordID = GetPlayerDiscordID(player)
        local discordTimestamp = math.floor(os.time())

        TriggerClientEvent('nd-notify:client:sendAlert', source, {
            type = 'success',
            text = 'You have clocked in as ' .. department .. ' (Callsign: ' .. callsign .. ', Badge: ' .. badgeNumber .. ').',
            length = 5000,
            style = { ['background-color'] = SUCCESS_COLOR, ['color'] = DARK_TEXT_COLOR }
        })

        local embed = {
            title = ':green_circle: Clock-In Notification',
            description = string.format(
                '**%s** (Callsign: %s, Badge: %s) has clocked in.\n\n**Player ID:** %d\n**Discord:** <@%s>',
                playerName, callsign, badgeNumber, player, discordID
            ),
            color = 65280,
            fields = {
                { name = 'Department', value = department, inline = true },
                { name = 'Badge Number', value = badgeNumber, inline = true },
                { name = 'Callsign', value = callsign, inline = true },
                { name = 'Clock-In Time', value = string.format('<t:%d:t>', discordTimestamp), inline = true }
            },
            footer = { text = 'Northern Bay RP - Logged by FiveM Server' }
        }
        PerformHttpRequest(Config.WEBHOOK_URL, function(statusCode, response, headers) end, 'POST', json.encode({ embeds = { embed } }), { ['Content-Type'] = 'application/json' })
    else
        TriggerClientEvent('nd-notify:client:sendAlert', source, {
            type = 'error',
            text = 'You do not have permission to use this command.',
            length = 5000,
            style = { ['background-color'] = ERROR_COLOR, ['color'] = TEXT_COLOR }
        })
    end
end, false)

RegisterCommand('911', function(source, args, rawCommand)
    local player = tonumber(source)
    local reason = table.concat(args, ' ')
    local coords = GetEntityCoords(GetPlayerPed(player))
    local nearestPostal = getNearestPostal(coords)

    if reason == '' then
        TriggerClientEvent('nd-notify:client:sendAlert', source, { 
            type = 'error',
            text = 'Usage: /911 [reason]',
            length = 5000,
            style = { ['background-color'] = '#FF0000', ['color'] = '#FFFFFF' }
        })
        return
    end

    for clockedInPlayer, info in pairs(onDutyPlayers) do
        TriggerClientEvent('nd-notify:client:sendAlert', clockedInPlayer, { 
            type = 'info',
            text = '911 Call: ' .. reason .. ' | Postal: ' .. nearestPostal,
            length = 10000,
            style = { ['background-color'] = '#0000FF', ['color'] = '#FFFFFF' }
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

        TriggerClientEvent('nd-notify:client:sendAlert', source, { 
            type = 'info',
            text = 'You have been on duty for ' .. timeString .. '.',
            length = 5000,
            style = { ['background-color'] = '#0000FF', ['color'] = '#FFFFFF' }
        })
    else
        TriggerClientEvent('nd-notify:client:sendAlert', source, { 
            type = 'error',
            text = 'You are not on duty.',
            length = 5000,
            style = { ['background-color'] = '#FF0000', ['color'] = '#FFFFFF' }
        })
    end
end, false)

RegisterCommand('clockout', function(source, args, rawCommand)
    local player = tonumber(source)

    if IsPlayerAceAllowed(player, Config.OffDutyACE) then
        if onDutyPlayers[player] then
            local playerDetails = onDutyPlayers[player]
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
            local department = playerDetails.department or "Unknown"
            local badgeNumber = playerDetails.badge or "Unknown"
            local callsign = playerDetails.callsign or "Unknown"
            local timestamp = os.date('%Y-%m-%d %H:%M:%S')
            local discordTimestamp = math.floor(os.time())

            TriggerClientEvent('nd-notify:client:sendAlert', source, { 
                type = 'success',
                text = 'You have clocked out. Duration: ' .. durationFormatted,
                length = 5000,
                style = { ['background-color'] = '#00FF00', ['color'] = '#000000' }
            })

            local embed = {
                title = ':red_circle: Clock-Out Notification',
                description = string.format(
                    '**%s** (Callsign: %s, Badge: %s) has clocked out.\n\n**Duration:** %s\n**Player ID:** %d\n**Discord:** <@%s>',
                    playerName,
                    callsign,
                    badgeNumber,
                    durationFormatted,
                    player,
                    discordID
                ),
                color = 16711680,
                fields = {
                    { name = 'Player Name:', value = playerName, inline = true },
                    { name = 'User ID:', value = discordID, inline = true },
                    { name = 'Department:', value = department, inline = true },
                    { name = 'Badge Number:', value = badgeNumber, inline = true },
                    { name = 'Callsign', value = callsign, inline = true },
                    { name = 'Clock-Out Time', value = string.format('<t:%d:t>', discordTimestamp), inline = true }
                },
                footer = { text = 'Your Server Name - Logged by FiveM Server' }
            }
            PerformHttpRequest(WEBHOOK_URL, function(statusCode, response, headers) end, 'POST', json.encode({ embeds = { embed } }), { ['Content-Type'] = 'application/json' })
        else
            TriggerClientEvent('nd-notify:client:sendAlert', source, { 
                type = 'error',
                text = 'You are not currently on duty.',
                length = 5000,
                style = { ['background-color'] = '#FF0000', ['color'] = '#FFFFFF' }
            })
        end
    else
        TriggerClientEvent('nd-notify:client:sendAlert', source, { 
            type = 'error',
            text = 'You do not have permission to use this command.',
            length = 5000,
            style = { ['background-color'] = '#FF0000', ['color'] = '#FFFFFF' }
        })
    end
end, false)

RegisterCommand('kickoffduty', function(source, args, rawCommand)
    local player = tonumber(source)
    local targetPlayerID = tonumber(args[1])

    if not targetPlayerID then
        TriggerClientEvent('nd-notify:client:sendAlert', source, { 
            type = 'error',
            text = 'Usage: /kickoffduty [targetPlayerID]',
            length = 5000,
            style = { ['background-color'] = '#FF0000', ['color'] = '#FFFFFF' }
        })
        return
    end

    if not IsPlayerAceAllowed(player, Config.KickAce) then
        TriggerClientEvent('nd-notify:client:sendAlert', source, { 
            type = 'error',
            text = 'You do not have permission to use this command.',
            length = 5000,
            style = { ['background-color'] = '#FF0000', ['color'] = '#FFFFFF' }
        })
        return
    end

    if not GetPlayerName(targetPlayerID) then
        TriggerClientEvent('nd-notify:client:sendAlert', source, { 
            type = 'error',
            text = 'The specified player (ID: ' .. targetPlayerID .. ') is not online or does not exist.',
            length = 5000,
            style = { ['background-color'] = '#FF0000', ['color'] = '#FFFFFF' }
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

        TriggerClientEvent('nd-notify:client:sendAlert', source, { 
            type = 'success',
            text = 'You have kicked ' .. playerName .. ' (ID: ' .. targetPlayerID .. ') off duty.',
            length = 5000,
            style = { ['background-color'] = '#00FF00', ['color'] = '#000000' }
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
        TriggerClientEvent('nd-notify:client:sendAlert', source, { 
            type = 'error',
            text = 'The specified player (ID: ' .. targetPlayerID .. ') is not currently on duty.',
            length = 5000,
            style = { ['background-color'] = '#FF0000', ['color'] = '#FFFFFF' }
        })
    end
end, false)


RegisterCommand('onduty', function(source, args, rawCommand)
    local player = source

    if IsPlayerAceAllowed(player, REQUIRED_PERMISSION) then
        local message = '^6On-duty players:\n'

        for targetPlayerID, data in pairs(onDutyPlayers) do
            local playerName = GetPlayerName(targetPlayerID)
            local department = data.department
            local badgeNumber = data.badge
            local callsign = data.callsign
            local formattedLine = '^7' .. playerName .. ' (' .. department .. ', Badge ' .. badgeNumber .. ', Call Sign ' .. callsign .. ') (ID: ' .. targetPlayerID .. ')\n'
            message = message .. formattedLine
        end

        TriggerClientEvent('chatMessage', player, message)
    else
        TriggerClientEvent('chatMessage', player, '^3You do not have permission to use this command.')
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
