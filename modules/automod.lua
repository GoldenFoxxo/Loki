local discordia = require('discordia')
local timer = require('timer')
local blist = {''}

local function onMessageCreate(msg)

    if msg.author.bot then
        return
    end
    
    for i = 1, #blist do
        if string.match(msg.content, blist[i]) then

            print(msg.author.tag..': '..msg.content)
            msg:delete()
            
            local remo = msg:reply('No links')
            if remo then
                timer.sleep(3000)
                remo:delete()
            end
            
        end
    end
end

local function onMessageUpdate(msg)
    for i = 1, #blist do
        if string.match(msg.content, blist[i]) then
            print(msg.author.tag..': '..msg.content)
            msg:delete()
        end
    end    
end

return {
	onMessageCreate = onMessageCreate,
    onMessageUpdate = onMessageUpdate
}