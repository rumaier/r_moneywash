---@diagnostic disable: undefined-global
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'r_moneywash'
description 'A simple money wash system for FiveM'
author 'r_scripts'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'locales/*.lua',
    'src/shared/*.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/**/server.lua',
    'src/server/*.lua',
}

client_scripts {
    'bridge/**/client.lua',
    'src/client/*.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
}