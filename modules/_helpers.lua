local discordia = require('discordia')

local function isOnline(member)
	return member.status ~= 'offline'
end

return {
    isOnline = isOnline
}