local discordia = require('discordia')
local client = discordia.Client()
local timer = require('timer')
local prefix = '?'
local app = {}
local cmds = {}
local replies = {}
require("discordia-components")

local verifyControls = discordia.Components {
    {
        id = "accept",
        type = "button",
        label = "Accept",
        style = "success"
    },
    {
        id = "deny",
        type = "button",
        label = "Deny",
        style = "danger"
    },
    {
        id = "kick",
        type = "button",
        label = "Kick",
        style = "danger"
    },
    {
        id = "ban",
        type = "button",
        label = "Ban",
        style = "danger"
    }
}

local function parseContent(content)
	if content:find(prefix, 1, true) ~= 1 then return end
	content = content:sub(prefix:len() + 1)
	local cmd, arg = content:match('(%S+)%s+(.*)')
	return cmd or content, arg
end

local function verify(msg)

	local cmd, arg = parseContent(msg.content)
	if not cmds[cmd] then return end

	if msg.member ~= msg.client.owner then
		print(msg.author.username, cmd) -- TODO: better command use logging
	end

	local success, content = pcall(cmds[cmd][1], arg, msg)

	local reply, err

	if success then -- command ran successfully

		if type(content) == 'string' then
			if #content > 1900 then
				reply, err = msg:reply {
					content = 'Content is too large. See attached file.',
					file = {os.time() .. '.txt', content},
					code = true,
				}
			elseif #content > 0 then
				reply, err = msg:reply(content)
			end
		elseif type(content) == 'table' then
			if content.content and #content.content > 1900 then
				local file = {os.time() .. '.txt', content.content}
				content.content = 'Content is too large. See attached file.'
				content.code = true
				if content.files then
					insert(content.files, file)
				else
					content.files = {file}
				end
			end
			reply, err = msg:reply(content)
		end

	else -- command produced an error, try to send it as a message

		reply = msg:reply {content = content,	code = 'lua'}

	end

	if reply then
		replies[msg.id] = reply
	elseif err then
		print(err)
	end

end

cmds['verify'] = {function(_, msg)
    verifyer = msg.guild:getMember(msg.member.id)

	if verifyer:send('Loading verification app form') then
		verifyer:send('Success')
		local success, msg = client:waitFor(verify, 10000, function(msg)
			return true
		end)
		if success == true then
			verifyer:reply('True')
		else
			verifyer:reply('False')
		end
	else
		local rmsg = msg:reply{mentions = {verifyer}, content = 'Unable to send verification in your DMs'}
		if rmsg then
			timer.setTimeout(3000, coroutine.wrap(function()
				rmsg:delete()
			end))
		end
	end
end, 'verifies the user.'}

return {
    verify = verify
}