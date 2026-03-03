fx_version 'cerulean'
game 'gta5'

description 'D3XL Vehicle Save - Saves vehicle positions across restarts'
author 'D3XL'
version '1.0.0'

shared_script 'config.lua'

client_scripts {
    'client.lua'
}

dependencies {
    'oxmysql'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

lua54 'yes'
