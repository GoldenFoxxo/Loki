local discordia = require('discordia')
local Date = discordia.Date
local helpers = loader.load('_helpers')
local sandbox = {}
local prefix = '?'

local f, upper, format = string.format, string.upper, string.format
local insert, concat, sort = table.insert, table.concat, table.sort

local client = discordia.Client {
	logFile = 'mybot.log',
	cacheAllMembers = true,
}

local function parseContent(content)
	if content:find(prefix, 1, true) ~= 1 then return end
	content = content:sub(prefix:len() + 1)
	local cmd, arg = content:match('(%S+)%s+(.*)')
	return cmd or content, arg
end

local cmds = {}
local replies = {}

local function onMessageCreate(msg)

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

local function code(str, msg)
	msg:reply(string.format('```\n%s```', str))
end

local function exec(arg, msg)
	if not arg then return end

	local lines = {}

	sandbox.require = require
	sandbox.client = client
	sandbox.msg = msg
	sandbox.discordia = discordia
	sandbox.print = function(...)
		msg.channel:send(...)
	end
	sandbox = setmetatable(sandbox, { __index = _G })

	local fn, syntaxError = load(arg, 'GoldenDragon Dev', 't', sandbox)
	if not fn then return code(syntaxError, msg) end

	if #lines > 0 then
		print('Success')
		return msg:reply{content = table.concat(lines, '\n'), code = 'lua'}
	end

	local success, runtimeError = pcall(fn)
	if not success then
		code(runtimeError, msg)
	else
		if not runtimeError then
		else
			return {
				embed = {
					title = "Eval",
					fields = {
						{name = 'Input', value = '```lua\n'..table.concat(args, ' ')..'```', inline = false},
						{name = 'Output', value = '```'..runtimeError..'```', inline = false}
					},
					color = discordia.Color.fromRGB(255, 215, 0).value,
					timestamp = discordia.Date():toISO('T', 'Z')
				}
			}
		end
	end
end

cmds['help'] = {function()
	local buf = {}
	for k, v in pairs(cmds) do
		insert(buf, f('%s - %s', k, v[2]))
	end
	sort(buf)
	return concat(buf, '\n')
end, 'This help command.'}

cmds['serverinfo'] = {function(_, msg)

	local guild = msg.guild
	local ownerId = msg.guild.ownerId

	return {
		embed = {
			thumbnail = {url = guild.iconURL},
			fields = {
				{name = 'Name', value = guild.name, inline = true},
				{name = 'ID', value = guild.id, inline = true},
				{name = 'Owner', value = msg.guild:getMember(ownerId).tag, inline = true},
				{name = 'Created', value = Date.fromSnowflake(guild.id):toISO(' ', ''), inline = true},
				{name = 'Members', value = guild.members:count(helpers.isOnline) .. ' / ' .. guild.totalMemberCount, inline = true},
				{name = 'Categories', value = tostring(#guild.categories), inline = true},
				{name = 'Text Channels', value = tostring(#guild.textChannels), inline = true},
				{name = 'Voice Channels', value = tostring(#guild.voiceChannels), inline = true},
				{name = 'Roles', value = tostring(#guild.roles), inline = true},
				{name = 'Emojis', value = tostring(#guild.emojis), inline = true}
			}
		}
	}

end, 'Provides information about the guild.'}

cmds['ping'] = {function(_, msg)

	local response = msg:reply('Pong!')

	if response then
  		response:setContent('Pong! '..'`'..math.abs(math.round((response.createdAt - msg.createdAt)*1000))..' ms`')
	end

end, 'Provides information about latency.'}

cmds['eval'] = {function(_, msg)
	if msg.author.id == msg.client.owner.id then
		args = msg.content:split(' ')
		table.remove(args,1)
		earg = table.concat(args,' ')
		exec(earg, msg)
	else
		msg:reply('Bot owner only!')
	end
end, 'Evaluates code.'}

cmds['kick'] = {function(_,msg)
	args = msg.content:split(" ")
	if msg.member:hasPermission(0x00000002) and not msg.member.bot then
		if args[2] then
			if tonumber(args[2]) then
				user = args[2]
			elseif msg.mentionedUsers.first then
				user = tostring(msg.mentionedUsers.first):split(' ')[2]
			else
				msg:reply('Invalid user')
			end
			table.remove(args, 2)
			table.remove(args, 1)
			if not args[1] then
				reason = "Unknown reason."
			else
				reason = tostring(table.concat(args, " "))
			end
			kick = msg.guild:kickUser(user, reason)
			if kick then
				msg:reply('Successfully kicked <@'..user..'> with reason: '..reason)
			else
				msg:reply('Invalid user')
			end
		else
			msg:reply('Invalid command.')
		end
	else
		msg:reply('You are not authorized to perform this command.')
	end
end, 'Kicks member.'}

cmds['ban'] = {function(_,msg)
	args = msg.content:split(" ")
	if msg.member:hasPermission(0x00000004) and not msg.member.bot then
		if args[2] then
			if tonumber(args[2]) then
				user = args[2]
			elseif msg.mentionedUsers.first then
				user = tostring(msg.mentionedUsers.first):split(' ')[2]
			else
				msg:reply('Invalid user')
			end
			table.remove(args, 2)
			table.remove(args, 1)
			if not args[1] then
				reason = "Unknown reason."
			else
				reason = tostring(table.concat(args, " "))
			end
			ban = msg.guild:banUser(user, reason)
			if ban then
				msg:reply('Successfully banned <@'..user..'> with reason: '..reason)
			else
				msg:reply('Invalid user')
			end
		else
			msg:reply('Invalid command.')
		end
	else
		msg:reply('You are not authorized to perform this command.')
	end
end, 'Bans member.'}

cmds['hug'] = {function(_,msg)

	function hug(uid)
		lhugs = {
			'*<@'..msg.author.id..'> tackles <@'..uid..'> from behind and gives them a massive hug*',
			'*<@'..msg.author.id..'> noticed <@'..uid..'> was feeling down and gave a hug to cheer them up*'
		}
		if uid == msg.author.id then
			msg:reply('You cannot hug youself')
		else
			msg:reply{content = lhugs[math.random(1,#lhugs)]}
		end
	end

	args = msg.content:split(' ')
	if msg.mentionedUsers.first then
		args[2] = tostring(msg.mentionedUsers.first):split(' ')[2]
		hug(args[2])
	elseif tonumber(args[2]) then
		if not msg.guild:getMember(args[2]) then
			msg:reply('Invalid user')
		else
			hug(args[2])
		end
	else
		msg:reply('You gotta have someone to hug')
	end

end, 'Hugs member.'}

cmds['kiss'] = {function(_,msg)

	function kiss(uid)
		lkiss = {
			'*<@'..uid..'> got the mega blushies after <@'..msg.author.id..'> kissed them*'
		}
		if uid == msg.author.id then
			msg:reply('You cannot kiss youself')
		else
			msg:reply{content = lkiss[math.random(1,#lhugs)]}
		end
	end

	args = msg.content:split(' ')
	if msg.mentionedUsers.first then
		args[2] = tostring(msg.mentionedUsers.first):split(' ')[2]
		kiss(args[2])
	elseif tonumber(args[2]) then
		if not msg.guild:getMember(args[2]) then
			msg:reply('Invalid user')
		else
			kiss(args[2])
		end
	else
		msg:reply('You gotta have someone to kiss')
	end
end, 'Kiss member.'}

cmds['boop'] = {function(_,msg)

	function boop(uid)
		lboops = {
			'*<@'..msg.author.id..'> ran up to <@'..uid..'> giving them a boop on the nose*',
			'*<@'..msg.author.id..'> saw that <@'..uid..'> wasn’t looking and booped the shit out of them*'
		}
		if uid == msg.author.id then
			msg:reply('You cannot boop youself')
		else
			msg:reply{content = lboops[math.random(1,#lboops)]}
		end
	end

	args = msg.content:split(' ')
	if msg.mentionedUsers.first then
		args[2] = tostring(msg.mentionedUsers.first):split(' ')[2]
		boop(args[2])
	elseif tonumber(args[2]) then
		if not msg.guild:getMember(args[2]) then
			msg:reply('Invalid user')
		else
			boop(args[2])
		end
	else
		msg:reply('You gotta have someone to boop')
	end
end, 'Boop member.'}

cmds['tug'] = {function(_,msg)

	function tug(uid)
		ltugs = {
			'*<@'..msg.author.id..'> went up and tugged <@'..uid..'>’s tail teasingly*'
		}
		if uid == msg.author.id then
			msg:reply('You cannot tug youself')
		else
			msg:reply{content = ltugs[math.random(1,#ltugs)]}
		end
	end

	args = msg.content:split(' ')
	if msg.mentionedUsers.first then
		args[2] = tostring(msg.mentionedUsers.first):split(' ')[2]
		tug(args[2])
	elseif tonumber(args[2]) then
		if not msg.guild:getMember(args[2]) then
			msg:reply('Invalid user')
		else
			tug(args[2])
		end
	else
		msg:reply('You gotta have someone to tug')
	end
end, 'Tug member.'}

cmds['dance'] = {function(_,msg)

	function dance(uid)
		ldance = {
			'*<@'..msg.author.id..'> started dancing with <@'..uid..'> when there favorite song came on*'
		}
		if uid == msg.author.id then
			msg:reply('You cannot dance with youself')
		else
			msg:reply{content = ldance[math.random(1,#ldance)]}
		end
	end

	args = msg.content:split(' ')
	if msg.mentionedUsers.first then
		args[2] = tostring(msg.mentionedUsers.first):split(' ')[2]
		dance(args[2])
	elseif tonumber(args[2]) then
		if not msg.guild:getMember(args[2]) then
			msg:reply('Invalid user')
		else
			dance(args[2])
		end
	else
		msg:reply('You gotta have someone to dance with')
	end
end, 'Dance with member.'}

return {
	onMessageCreate = onMessageCreate,
	onMessageDelete = onMessageDelete,
}