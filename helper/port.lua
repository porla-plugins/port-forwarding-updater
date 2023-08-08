local log      = require("log")
local sessions = require("sessions")

return {
    get_listening = function(session_name, interface)
        local settings = sessions.settings.get(session_name)
        local _, _, current_port = string.find(settings.listen_interfaces, interface.."%:(%d+)")
        return tonumber(current_port) or 0
    end,

    set_listening = function(session_name, interface, target_port)
        --check if port_num is a number between 1 and 65535
        local t = tonumber(target_port)
        if not (t >= 1 and t <= 65535) then
            log.warning("Port-Forwarding-Updater: Port Number is not between 1 and 65535")
            goto done
        end

        local settings = sessions.settings.get(session_name)
        local s = settings.listen_interfaces
        if string.find(s, interface) then
            s = string.gsub(s, interface.."%:?%d*", interface..":"..tostring(target_port))
        elseif s == "" then
            s = interface..":" .. tostring(target_port)
        else
            s = s .. "," .. interface .. ":" .. tostring(target_port)
        end

        settings.listen_interfaces = s
        sessions.settings.set(session_name, settings)

        local verify_settings = sessions.settings.get(session_name)
        local new_listen_interfaces = verify_settings.listen_interfaces
        log.debug("Listening Interface for session " .. session_name .. " set to: " .. new_listen_interfaces)

        ::done::

    end,

    read_portfile = function(path)
        local file = assert(io.open(path, "r"))
        if not file then return nil end
        local port = file:read("*n")
        file:close()
        return port
    end,

    cancel = function()
    end
}