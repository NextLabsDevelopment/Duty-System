fx_version 'cerulean'
games { 'gta5' }

author 'Next Dev Labs'
description 'Free Standalone Duty System'
version '1.2'

shared_script 'config.lua'

server_script 'server.lua'

client_script 'client.lua'

exports {
    'GetOnDutyOfficers', -- Exporting the global function to check if the player is on duty
}