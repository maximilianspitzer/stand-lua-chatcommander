-- ChatCommander Helpers

local utils = {}

local constants = require("chat_commander/constants")
local config = require("chat_commander/config")

utils.debug_log = function(message)
    if config.debug ~= false then
        util.log("[ChatCommander] "..message)
    end
end

utils.replace_command_character = function(message)
    local chat_control_character = constants.control_characters[config.chat_control_character_index][2]
    return message:gsub(" !", " "..chat_control_character)
end

utils.add_reply_prefix = function(message)
    local reply_prefix = constants.reply_characters[config.reply_prefix_index][2]
    if reply_prefix ~= "None" then
        message = reply_prefix .. " " .. message
    end
    return message
end

local function send_message(pid, message)
    message = utils.replace_command_character(message)
    message = utils.add_reply_prefix(message)
    if config.reply_visible_to_all then
        --message = PLAYER.GET_PLAYER_NAME(pid) .. " " .. message
        chat.send_message(message, false, true, true)
        --local say_command_ref = menu.ref_by_path("Online>Chat>Send Message>Send Message")
        --if menu.is_ref_valid(say_command_ref) then
        --    menu.trigger_command(say_command_ref, message)
        --else
        --    util.toast("Invalid menu item")
        --end
    else
        chat.send_targeted_message(pid, pid, message, false)
    end
end


utils.help_message = function(pid, message)
    if pid ~= nil and message ~= nil then
        if (type(message) == "table") then
            for _, message_part in pairs(message) do
                send_message(pid, message_part)
            end
        else
            send_message(pid, message)
        end
    end
end

-- From https://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating
utils.array_remove = function(t, fnKeep)
    local j, n = 1, #t;
    for i=1,n do
        if (fnKeep(t, i, j)) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end
    return t;
end



utils.bit_test = function(value, bit)
    return value & (1 << bit) ~= 0
end

utils.bit_set = function(value, bit)
    return value | (1 << bit)
end

utils.bit_clear = function(value, bit)
    return value & ~(1 << bit)
end

utils.array_reverse = function(x)
    local n, m = #x, #x/2
    for i=1, m do
        x[i], x[n-i+1] = x[n-i+1], x[i]
    end
    return x
end

utils.get_chat_control_character = function()
    return constants.control_characters[config.chat_control_character_index][2]
end

utils.combine_remaining_commands = function(commands, start_index)
    local response = ""
    for index, command in commands do
        if index >= start_index then
            response = response .. command
        end
    end
    -- Strip out any special characters
    response = response:gsub('[%p%c%s]', '')
    return response
end

utils.table_copy = function(obj)
    if type(obj) ~= 'table' then
        return obj
    end
    local res = setmetatable({}, getmetatable(obj))
    for k, v in pairs(obj) do
        res[utils.table_copy(k)] = utils.table_copy(v)
    end
    return res
end

utils.str_starts_with = function(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

utils.strsplit = function(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

utils.get_enum_value_name = function(enum_name, enum_value)
    for key, value in pairs(enum_name) do
        if enum_value == value then
            return key
        end
    end
end

utils.is_player_within_dimensions = function(pid, dimensions)
    local player_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
    return utils.is_position_within_dimensions(player_pos, dimensions)
end

utils.is_position_within_dimensions = function(position, dimensions)
    return (
        position.x > dimensions.min.x and position.x < dimensions.max.x
        and position.y > dimensions.min.y and position.y < dimensions.max.y
        and position.z > dimensions.min.z and position.z < dimensions.max.z
    )
end

utils.is_player_in_casino = function(pid)
    return utils.is_player_within_dimensions(pid, {
        min={
            x=1073.9967,
            y=189.58717,
            z=-53.838943,
        },
        max={
            x=1166.935,
            y=284.88977,
            z=-42.28554,
        },
    })
end

utils.is_player_on_airfield = function(pid)
    local airfield_rects = {
        -- Main airport southern runways
        {
            min={x=-1955, y=-3550, z=0},
            max={x=-950, y=-2600, z=20},
        },
        -- West runways
        {
            min={x=-1730, y=-2720, z=0},
            max={x=-1225, y=-2125, z=20},
        },
        -- Airport2
        {
            min={x=990, y=2950, z=30},
            max={x=1850, y=3390, z=50},
        },
    }
    for _, airfield_rect in airfield_rects do
        if utils.is_player_within_dimensions(pid, airfield_rect) then
            return true
        end
    end
    return false
end

utils.is_in = function(needle, list)
    for _, item in pairs(list) do
        if item == needle then
            return true
        end
    end
    return false
end

utils.get_on_off = function(command)
    return command ~= "off"
end

utils.get_on_off_string = function(command)
    return (utils.get_on_off(command) and "ON" or "OFF")
end

utils.delete_menu_list = function(menu_list)
    if type(menu_list) ~= "table" then return end
    for k, h in pairs(menu_list) do
        if h:isValid() then
            menu.delete(h)
        end
        menu_list[k] = nil
    end
end

utils.is_player_blessed = function(pid)
    for _, player_name in config.blessed_players do
        if players.get_name(pid) == player_name then
            return true
        end
    end
    return false
end

utils.is_player_friend = function(pid)
    for friend_index = 1,NETWORK.NETWORK_GET_FRIEND_COUNT() do
        if NETWORK.NETWORK_GET_FRIEND_DISPLAY_NAME(friend_index) == players.get_name(pid) then
            return true
        end
    end
    return false
end

utils.is_player_authorized = function(pid)
    if config.authorized_for.everyone then
        return true
    end

    if config.authorized_for.me and pid == players.user() then
        return true
    end

    if config.authorized_for.friends and utils.is_player_friend(pid) then
        return true
    end

    if config.authorized_for.blessed and utils.is_player_blessed(pid) then
        return true
    end

    return false
end

utils.is_player_authorized_for_chat_command = function(pid, chat_command)
    if chat_command.authorized_for.everyone then
        return true
    end

    if chat_command.authorized_for.me and pid == players.user() then
        return true
    end

    if chat_command.authorized_for.friends and utils.is_player_friend(pid) then
        return true
    end

    if chat_command.authorized_for.blessed and utils.is_player_blessed(pid) then
        return true
    end

    return false
end


utils.require_dependency = function(dependency_path)
    local dep_status, required_dep = pcall(require, dependency_path)
    if not dep_status then
        util.log("Could not load "..dependency_path..": "..required_dep)
    else
        return required_dep
    end
end

utils.require_constructor_lib = function()
    local constructor_lib = utils.require_dependency("constructor/constructor_lib")
    if not constructor_lib then
        util.toast("This command relies on constructor_lib. Please install Constructor to use this command.", TOAST_ALL)
        return
    end
    return constructor_lib
end

return utils
