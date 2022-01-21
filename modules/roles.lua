local discordia = require('discordia')
local client = discordia.Client()

local lrole = {
    {'928787932632973322'},
    {'⛏️','🪓','🔫','🔨','❤️','🐲','🏵️','⚔️','🗡️','🔪'},
    {'928790739624816651','928790685124018226','928797826325037086','928797951940251679','928797880960036914','928798477461389332','928797910005608450','928798205712429136','928798089773473863','928798134983852113'},
    {'928803209479335946'},
    {'💻','928802545927876728','928803066797510726','928803045540769824'},
    {'928815260809453578','928815347866415174','928815297316667462','928815318942498906'},
    {'928824919624659004'},
    {'💙','❤️','💜'},
    {'928825470374543410','928825572589711421','928825592420388904'}
}

local function onReactionAdd(channel, messageId, hash, userId)

    local guild = channel.guild
    local member = guild:getMember(userId)

    print("In "..channel.name..", "..userId.." has reacted using "..hash)

    for i = 1, #lrole do
        if lrole[i][1] == messageId then
            for a = 1, #lrole[i+1] do
                if lrole[i+1][a] == hash then
                    if not member:hasRole(lrole[i+2][a]) then
                        return member:addRole(lrole[i+2][a])
                    end
                end
            end
        end
    end
end

local function onReactionRemove(channel, messageId, hash, userId)

    local guild = channel.guild
    local member = guild:getMember(userId)

    print("In "..channel.name..", "..userId.." has reacted using "..hash)

    for i = 1, #lrole do
        if lrole[i][1] == messageId then
            for a = 1, #lrole[i+1] do
                if lrole[i+1][a] == hash then
                    if member:hasRole(lrole[i+2][a]) then
                        return member:removeRole(lrole[i+2][a])
                    end
                end
            end
        end
    end
end

return {
    onReactionAdd = onReactionAdd,
    onReactionRemove = onReactionRemove
}