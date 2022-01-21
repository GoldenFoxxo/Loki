local discordia = require('discordia')
local fs = require('fs')
local json = require('json')
local client = discordia.Client()
discordia.extensions()

local config = json.decode(fs.readFileSync('config.json'))

local loader = require('./loader')
local modules = loader.modules

client:on('ready', function()
	print('Logged in as '.. client.user.username)
end)

client:on('messageCreate', function(msg)

	if modules.commands then
		modules.commands.onMessageCreate(msg)
	end

	if modules.verification then
		modules.verification.verify(msg)
	end

end)

client:on('messageUpdate', function(msg)

end)

client:on('reactionAddUncached', function(channel, messageId, hash, userId)

	if modules.roles then
		modules.roles.onReactionAdd(channel, messageId, hash, userId)
	end

end)

client:on('reactionRemoveUncached', function(channel, messageId, hash, userId)

	if modules.roles then
		modules.roles.onReactionRemove(channel, messageId, hash, userId)
	end

end)

client:run('Bot '..config.token)
