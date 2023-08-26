local log      = require("log")
local sessions = require("sessions")

local function is_ipv6(ip)
    local _, c = string.gsub(ip, ":","")
    if c > 1 then return true else return false end
end

return {
    get_interface_amount = function(session_name)
        local session = sessions.get(session_name)
        local settings = session:settings()
        local listen_interfaces = settings.listen_interfaces

        if listen_interfaces == "" or nil then
            return 0
        else
            local _, count = string.gsub(listen_interfaces, ",","")
            return count + 1
        end
    end,

    get_listening = function(session_name, interface)
        local session = sessions.get(session_name)
        local settings = session:settings()
        local current_port = 0
        if is_ipv6(interface) then
            _, _, current_port = string.find(settings.listen_interfaces, interface.."%]%:(%d+)")
        else
            _, _, current_port = string.find(settings.listen_interfaces, interface.."%:(%d+)")
        end

        return tonumber(current_port)
    end,

    set_listening = function(session_name, interface, target_port, replace_existing)
        --check if port_num is a number between 1 and 65535
        if not (tonumber(target_port) >= 1 and tonumber(target_port) <= 65535) then
            log.warning("Port-Forwarding-Updater: Port Number is not between 1 and 65535")
            goto done
        end

        local session = sessions.get(session_name)
        local settings = session:settings()

        if replace_existing then
            if is_ipv6(interface) then
                settings.listen_interfaces = "["..interface.."]:"..tostring(target_port)
            else
                settings.listen_interfaces = interface..":"..tostring(target_port)
            end

            session:apply_settings(settings)
            local verify_settings = session:settings()
            local s = verify_settings.listen_interfaces
            log.debug("Listening Interface(s) for session " .. session_name .. " set to: " .. s)

            goto done
        end

        local s = settings.listen_interfaces
        local split_interfaces = {}
        for split_interface in string.gmatch(s, "([^,]+)") do
            if is_ipv6(split_interface) then
                if string.find(split_interface, "%]") then
                    local i = string.gsub(s, "%[", "")
                    i = string.gsub(i, "%].*", "")
                    local p = string.gsub(s, "%[.*]%:?", "")
                    split_interfaces[i] = p
                else
                    split_interfaces[split_interface] = ""
                end
            else
                local i_table = {}
                for j in string.gmatch(split_interface, "([^:]+)") do
                    table.insert(i_table, j)
                end
                if #i_table == 1 then
                    split_interfaces[i_table[1]] = ""
                elseif #i_table == 2 then
                    split_interfaces[i_table[1]] = i_table[2]
                else
                    log.warning("Invalid interface and port pair.")
                end
            end
        end

        split_interfaces[interface] = tostring(target_port)

        local new_listen_interfaces = ""
        for k, v in pairs(split_interfaces) do
            if is_ipv6(k) then
                if new_listen_interfaces == "" then
                    if v == "" or v == nil then
                        new_listen_interfaces = k
                    else
                        new_listen_interfaces = "["..k.."]:"..v
                    end
                else
                    if v == "" or v == nil then
                        new_listen_interfaces = new_listen_interfaces..","..k
                    else
                        new_listen_interfaces = new_listen_interfaces..",["..k.."]:"..v
                    end
                end
            else
                if new_listen_interfaces == "" then
                    if v == "" or v == nil then
                        new_listen_interfaces = k
                    else
                        new_listen_interfaces = k..":"..v
                    end
                else
                    if v == "" or v == nil then
                        new_listen_interfaces = new_listen_interfaces..","..k
                    else
                        new_listen_interfaces = new_listen_interfaces..","..k..":"..v
                    end
                end
            end
        end

        ::set_interfaces::

        settings.listen_interfaces = new_listen_interfaces
        session:apply_settings(settings)

        local verify_settings = session:settings()
        s = verify_settings.listen_interfaces
        log.debug("Listening Interface(s) for session " .. session_name .. " set to: " .. s)

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