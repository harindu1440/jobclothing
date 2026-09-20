fx_version 'cerulean'
game 'gta5'

name        'jobclothing'
description 'Job Clothing System — QBCore / QBox compatible'
version     '1.0.0'
author      'flex'

-- Shared files loaded on both client and server
shared_scripts {
    'config.lua',
    'shared/constants.lua',
    'shared/utils.lua',
}

-- Server-side scripts
server_scripts {
    '@oxmysql/lib/MySQL.lua',          -- optional; safe if missing when using JSON fallback
    'server/framework/qbcore.lua',
    'server/framework/qbox.lua',
    'server/framework/adapter.lua',
    'server/permissions.lua',
    'server/peds.lua',
    'server/uniforms.lua',
    'server/main.lua',
}

-- Client-side scripts
client_scripts {
    'client/clothing/illenium.lua',
    'client/clothing/fivem-appearance.lua',
    'client/clothing/qb-clothing.lua',
    'client/clothing/adapter.lua',
    'client/placement.lua',
    'client/ped_manager.lua',
    'client/interaction.lua',
    'client/main.lua',
}

-- NUI files
ui_page 'dist/index.html'

files {
    'dist/**',
    'dist/assets/**',
}

-- ox_lib integration (optional but enhances UX)
-- dependency 'ox_lib'

lua54 'yes'
