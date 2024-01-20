fx_version 'cerulean'
game 'gta5'

author 'jackp'
description ''
version '1.0.1'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

client_script {
    '@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/ComboZone.lua',
    'client/main.lua'
}

--ui_page 'html/index.html'

--files {
--	'html/*.html',
--	'html/*.js',
--	'html/*.png',
--	'html/*.css',
--}

lua54 'yes'
