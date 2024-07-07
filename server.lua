local onDutyPlayers = {} 
local dutyStartTime = {} 

local REQUIRED_PERMISSION = 'duty.view'

local WEBHOOK_URL = 'YOUR_WEBHOOK_HERE'

function GetPlayerDiscordID(player)
    for _, identifier in ipairs(GetPlayerIdentifiers(player)) do
        if identifier:match("discord") then
            return identifier:gsub("discord:", "")
        end
    end
    return nil
end

RegisterCommand('clockin', function(source, args, rawCommand)
    local player = source
    local department = args[1]
    local badgeNumber = args[2]

    if not department or not badgeNumber then
        TriggerClientEvent('chatMessage', player, '^3Usage: /clockin [department] [badge]')
        return
    end

    if IsPlayerAceAllowed(player, 'duty.clockin') then
        if not onDutyPlayers[player] then
            onDutyPlayers[player] = { department = department, badge = badgeNumber }
            dutyStartTime[player] = os.time()

            local playerName = GetPlayerName(player)
            local playerID = player
            local discordID = GetPlayerDiscordID(player)

            TriggerClientEvent('chatMessage', player, '^2You have clocked in as ' .. department .. ' (Badge ' .. badgeNumber .. ').')

            local timestamp = os.date('%Y-%m-%d %H:%M:%S')
            local embed = {
                title = ':green_circle: Clock-In',
                description = playerName .. ' (' .. department .. ', Badge ' .. badgeNumber .. ') has clocked in. (<@' .. discordID .. '>)',
                color = 65280,
                footer = { text = 'Player ID: ' .. playerID .. ' | ' .. timestamp }
            }
            PerformHttpRequest(WEBHOOK_URL, function(statusCode, response, headers) end, 'POST', json.encode({ embeds = { embed } }), { ['Content-Type'] = 'application/json' })
        else
            TriggerClientEvent('chatMessage', player, '^3You are already on duty.')
        end
    else
        TriggerClientEvent('chatMessage', player, '^3You do not have permission to use this command.')
    end
end, false)

RegisterCommand('clockout', function(source, args, rawCommand)
    local player = source

    if IsPlayerAceAllowed(player, 'duty.clockout') then
        if onDutyPlayers[player] then
            local startTime = dutyStartTime[player]
            local currentTime = os.time()
            local durationSeconds = currentTime - startTime
            local durationFormatted = FormatDuration(durationSeconds)

            onDutyPlayers[player] = nil
            dutyStartTime[player] = nil

            local playerName = GetPlayerName(player)
            local playerID = player
            local discordID = GetPlayerDiscordID(player)

            TriggerClientEvent('chatMessage', player, '^1You have clocked out. (Duration: ' .. durationFormatted .. ')')

            local timestamp = os.date('%Y-%m-%d %H:%M:%S')
            local embed = {
                title = ':red_circle: Clock-Out',
                description = playerName .. ' has clocked out. (Duration: ' .. durationFormatted .. ') (<@' .. discordID .. '>)',
                color = 16711680,
                footer = { text = 'Player ID: ' .. playerID .. ' | ' .. timestamp }
            }
            PerformHttpRequest(WEBHOOK_URL, function(statusCode, response, headers) end, 'POST', json.encode({ embeds = { embed } }), { ['Content-Type'] = 'application/json' })
        else
            TriggerClientEvent('chatMessage', player, '^3You are already off duty.')
        end
    else
        TriggerClientEvent('chatMessage', player, '^3You do not have permission to use this command.')
    end
end, false)


RegisterCommand('kickoffduty', function(source, args, rawCommand)
    local player = source
    local targetPlayerID = tonumber(args[1])

    if not targetPlayerID then
        TriggerClientEvent('chatMessage', player, '^3Usage: /kickoffduty [targetPlayerID]')
        return
    end

    if not IsPlayerAceAllowed(player, 'duty.kickoff') then
        TriggerClientEvent('chatMessage', player, '^3You do not have permission to use this command.')
        return
    end

    if onDutyPlayers[targetPlayerID] then
        onDutyPlayers[targetPlayerID] = nil
        dutyStartTime[targetPlayerID] = nil

        local playerName = GetPlayerName(targetPlayerID)
        local discordID = GetPlayerDiscordID(targetPlayerID)

        TriggerClientEvent('chatMessage', player, '^1You have kicked ' .. playerName .. ' (ID: ' .. targetPlayerID .. ') off duty.')

        local timestamp = os.date('%Y-%m-%d %H:%M:%S')
        local embed = {
            title = ':red_circle: Kicked Off Duty',
            description = playerName .. ' (ID: ' .. targetPlayerID .. ') has been kicked off duty by ' .. GetPlayerName(player) .. '. (<@' .. discordID .. '>)',
            color = 16711680, 
            footer = { text = 'Kicked by: ' .. GetPlayerName(player) .. ' | ' .. timestamp }
        }
        PerformHttpRequest(WEBHOOK_URL, function(statusCode, response, headers) end, 'POST', json.encode({ embeds = { embed } }), { ['Content-Type'] = 'application/json' })

    else
        TriggerClientEvent('chatMessage', player, '^3The specified player (ID: ' .. targetPlayerID .. ') is not currently on duty.')
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
            local formattedLine = '^7' .. playerName .. ' (' .. department .. ', Badge ' .. badgeNumber .. ') (ID: ' .. targetPlayerID .. ')\n'
            message = message .. formattedLine
        end

        TriggerClientEvent('chatMessage', player, message)
    else
        TriggerClientEvent('chatMessage', player, '^3You do not have permission to use this command.')
    end
end, false)


function FormatDuration(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local seconds = seconds % 60
    return string.format('%02d:%02d:%02d', hours, minutes, seconds)
end
