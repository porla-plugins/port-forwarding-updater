local port   = require("helper.port")

local config = require("config")
local cron   = require("cron")
local log    = require("log")

local cron_jobs = {}

local function checkport(session_name, target_interface, file_path)
    local current_port = port.get_listening(session_name, target_interface)
    local target_port  = port.read_portfile(file_path)

    --nil if port.dat contains no valid number
    if target_port then
        if current_port ~= target_port then
            port.set_listening(session_name, target_interface, target_port)
        end
    else
        log.debug("Port-Forwarding-Updater: No port file or port found. Not setting anything.")
    end
end

function porla.init()
    if config == nil then
        log.warning("No config provided for port-forwarding-updater plugin.")
        return false
    end

    --run it once for 'startup' port setting
    log.debug("Port-Forwarding-Updater Plugin Loaded. Performing initial check.")
    for _, v in ipairs(config) do
        --initial run on startup
        checkport(v.session_name, v.listen_interface, v.path)

        cron_jobs[v.session_name] = cron.schedule({
            expression = v.cron,
            callback = function()
                checkport(v.session_name, v.listen_interface, v.path)
            end
        })
    end

    return true
end

function porla.destroy()
    --cancel all running cron jobs
    if next(cron_jobs) ~= nil then
        for _, v in ipairs(cron_jobs) do
            v.cancel()
        end
    end
end


