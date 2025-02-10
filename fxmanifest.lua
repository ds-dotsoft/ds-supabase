fx_version 'cerulean'
game 'gta5'

author 'dotsoft/jason & alex'
description 'A complete Supabase wrapper for FiveM'
version '1.0.0'

lua54 'yes'

shared_script '@ox_lib/init.lua'

-- Only a server script is required for this secure API wrapper.
server_script 'server/main.lua'
