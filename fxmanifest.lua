fx_version 'cerulean'
game 'gta5'

lua54 'yes'

ui_page 'html/index.html'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua',
    'config_condition.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'html/index.html',
    'html/script.js',
    'html/style.css',
    'html/img/dudaplus.png',
    'html/img/default.png'
}
