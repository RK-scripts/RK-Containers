
fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'RK Container Script'
version '1.0.0'

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'config.lua',
    'server.lua'
}

client_scripts {
    'config.lua',
    'client.lua'
}

dependencies {
    'es_extended',
    'ox_inventory',
    'ox_target'
}