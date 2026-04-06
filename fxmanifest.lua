fx_version 'cerulean'
game 'gta5'


author 'negan/bldr'
description 'Street selling'
version '1.0.0'




shared_scripts { 'config.lua' }
client_scripts { 'client/*.lua' }
server_scripts { 'server/*.lua' }

ui_page 'web/dist/index.html'
files { 'web/dist/**/*' }

dependencies {
    'qb-core',
    'ox_lib'
}
