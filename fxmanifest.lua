---@diagnostic disable: undefined-global

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'r_moneywash'
description 'A simple money wash system for FiveM'
author 'r_scripts'
version '1.1.0'

shared_scripts {
  '@ox_lib/init.lua',
  'utils/shared.lua',
  'locales/*.lua',
  'configs/*.lua'
}

server_scripts {
  'utils/server.lua',
  'core/server/*.lua',
}

client_scripts {
  'utils/client.lua',
  'core/client/*.lua',
}

dependencies {
  'ox_lib',
  'r_bridge',
}