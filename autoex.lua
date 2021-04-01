_addon.name     = 'autoex'
_addon.author   = 'Elidyr'
_addon.version  = '0.20210331'
_addon.command  = 'ax'

require('tables')
require('strings')
require('logger')

local chat_modes    = {[0]='say', [1]='shout', [3]='tell', [4]='party', [5]='linkshell', [26]='yell', [27]='linkshell', [33]='unity'}
local player        = windower.ffxi.get_player()
local res           = require('resources')
local files         = require('files')
local events        = {build={}, registered={}, helpers={}}
local color         = '50,220,175'

-- XML Parsing.
local parse = function(content)
    local content   = content or false
    local events    = {}
    local captures  = {

        ['header']  = '(<xml version="[%d%.]+">)',
        ['start']   = '<autoexec>',
        ['import']  = '<import>(.*)</import>',
        ['event']   = '<register event="([%w%_]+)" silent="([truefalse]+)" runonce="([truefalse]+)">(.*)</register>',
        ['start']   = '</autoexec>',

    }
    if not content then
        return false
    end

    for c in content:it() do

        if c:match('&lt;') then
            c = c:gsub('&lt;', '<')
        end

        if c:match('&gt;') then
            c = c:gsub('&gt;', '>')
        end

        if c:match(captures['event']) then
            local t = T{c:match(captures['event'])}
            
            if t and t[1] then
                events[t[1]] = {name=t[1], silent=t[2], once=t[3], command=t[4]}
            end

        end

    end
    return events

end

-- Build the convert directory and settings directory.
local convert    = files.new('/convert/instructions.lua')
local settings  = files.new(('/settings/%s.xml'):format(player.name))
if not convert:exists() then
    convert:write('-- COPY ALL YOUR OLD XML FILES YOU WANT TO CONVERT IN TO THIS FOLDER AND FOLLOW THE IN GAME HELP.\n-- //ax help\n-- //ax convert <file_name>')

end

if not settings:exists() then
    settings:write(('return %s'):format(T({}):tovstring()))
    
end

-- Simple round funciton.
math.round = function(num)
    if num >= 0 then return math.floor(num+.5) 
    else return math.ceil(num-.5) end
end

windower.register_event('addon command', function(...)
    local commands  = T{...}
    local command   = commands[1] or false

    if command then
        local command = command:lower()

        if command == 'convert' and commands[2] then
            local fname = {}
            for i=2, #commands do
                table.insert(fname, commands[i])
            end
            events.helpers['convert'](table.concat(fname, ' '))

        elseif command == 'load' and commands[2] then
            local fname = {}
            for i=2, #commands do
                table.insert(fname, commands[i])
            end

            events.helpers['clear'](function()
                events.helpers['load'](table.concat(fname, ' '))
            end)

        elseif command == 'debug' then
            table.print(events.registered)

        end

    end

end)

events.helpers['convert'] = function(filename)
    if not filename then
        return false
    end
    
    local f = files.new(('/convert/%s.xml'):format(filename))
    if f:exists() then
        local n = files.new(('/settings/%s.lua'):format(filename))
        n:write(('return %s'):format(T(parse(f)):tovstring()))
    end

end

events.helpers['load'] = function(filename)
    if not filename then
        return false
    end

    local f = files.new(('/settings/%s.lua'):format(filename))
    if f:exists() then
        local temp = dofile(('%s/settings/%s.lua'):format(windower.addon_path, filename))
        
        if temp then
        
            for i,v in pairs(temp) do
                table.insert(events.build, v)
            end
            events.helpers.build()

        end

    end

end

events.helpers['clear'] = function(callback)
    for _,v in pairs(events.registered) do
        windower.unregister_event(v.id)
    end
    events.build = {}

    if callback and type(callback) == 'function' then
        callback()
    end

end

events.helpers['build'] = function()
    
    for _,v in ipairs(events.build) do
        
        if v.name then
            local split = v.name:split('_')

            if split[1] and events.helpers[split[1]] then
                events.helpers[split[1]](v.name, v.command, v.silent, v.once)
            end

        end

    end

end

events.helpers['login'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] then
        local player = split[2]

        if player then
            events.registered[event] = {event=event, id=windower.register_event('login', function(name)
                if name:lower() == player:lower() then
                    windower.send_command(command)

                    if once then
                        windower.unregister_event(events.registered[event].id)
                    end

                end

            end)}

            if not silent then
                print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
            end

        else
            events.registered[event] = {event=event, id=windower.register_event('login', function()
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end)}

            if not silent then
                print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
            end

        end

    end

end

events.helpers['logout'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] then
        local player = split[2]

        if player then
            events.registered[event] = {event=event, id=windower.register_event('login', function(name)
                if name:lower() == player:lower() then
                    windower.send_command(command)

                    if once then
                        windower.unregister_event(events.registered[event].id)
                    end

                end

            end)}

            if not silent then
                print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
            end

        else
            events.registered[event] = {event=event, id=windower.register_event('login', function()
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end)}

            if not silent then
                print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
            end

        end

    end

end

events.helpers['chat'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['time'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] then
        local temp = split[2]:split('.')

        if temp and temp[1] and temp[2] then
            local time  = {h=tonumber(temp[1]), m=tonumber(temp[2])}

            events.registered[event] = {event=event, id=windower.register_event('time change', function(new, old)
                local hour      = tonumber(math.floor(windower.ffxi.get_info().time/60))
                local minute    = tonumber(math.round(((windower.ffxi.get_info().time/60)-hour)*60))

                if new and hour == time.h and minute == time.m then
                    windower.send_command(command)

                    if once then
                        windower.unregister_event(events.registered[event].id)
                    end

                end

            end)}

            if not silent then
                print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
            end

        end

    end

end

events.helpers['invite'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['gainbuff'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['losebuff'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['day'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['moon'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['zone'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['lvup'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['lvdown'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['gainexp'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['chain'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['weather'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['status'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['examined'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['noammo'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['tp'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['unload'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['hp'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['hpp'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['lowhp'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['criticalhp'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['hpmax'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['mp'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['mpp'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['lowmp'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['criticalmp'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

events.helpers['mpmax'] = function(event, command, silent, once)
    local once      = once == 'true' and true or false
    local silent    = silent == 'true' and true or false
    local split     = event:split('_')

    if event and command and split[2] and split[3] and split[4] then
        local m         = split[2]
        local player    = split[3]
        local find      = split[4]

        events.registered[event] = {event=event, id=windower.register_event('chat message', function(message, sender, mode)
            if message and sender and mode and m == chat_modes[mode] and player:lower() == sender:lower() and message:match(find) then
                windower.send_command(command)

                if once then
                    windower.unregister_event(events.registered[event].id)
                end

            end

        end)}

        if not silent then
            print(('%s registered! Execute: %s - Flags: Silent: %s, RunOnce: %s'):format(event, command, tostring(silent), tostring(once)))
        end

    end

end

--Copyright © 2021, eLiidyr
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of <addon name> nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.

--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.