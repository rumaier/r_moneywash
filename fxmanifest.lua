---@diagnostic disable: undefined-global
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'r_moneywash'
description 'A simple money wash system for FiveM'
author 'r_scripts'
version '1.0.5'

shared_scripts {
    '@ox_lib/init.lua',
    'utils/shared.lua',
    'locales/*.lua',
    'config.lua',
}

server_scripts {
    'utils/server.lua',
    'src/server/*.lua',
}

client_scripts {
    'utils/client.lua',
    'src/client/*.lua',
}


dependencies {
    'ox_lib',
    'r_bridge',
}

escrow_ignore {
    'install/**/*.*',
    'locales/*.*',
    'config.*' 
}